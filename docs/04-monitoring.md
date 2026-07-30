# Monitoring — Homelab

Suivi de la mise en place du stack monitoring (node-exporter, Prometheus, Grafana, Uptime Kuma).

## Réseau

Tous les services rejoignent le réseau Docker partagé `homelab` (déclaré en `external: true` dans chaque `compose.yaml`), pour que les conteneurs puissent se résoudre entre eux par leur nom (ex. `node-exporter:9100`, `pihole`) plutôt que par IP.

---

## node-exporter

📍 Dossier : `~/homelab/docker/monitoring/node-exporter/`

- Image : `prom/node-exporter:latest`
- Expose les métriques système (CPU, RAM, disque, réseau) du Raspberry Pi sur le port `9100`

### Installation

```bash
mkdir -p ~/homelab/docker/monitoring/node-exporter
cd ~/homelab/docker/monitoring/node-exporter
nano compose.yaml
```

```yaml
services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    networks:
      - homelab

networks:
  homelab:
    external: true
```

```bash
docker compose up -d
docker ps
```

### Vérification

`http://192.168.1.50:9100/metrics` doit afficher une longue liste de métriques.

### Résolution de problèmes rencontrés

**⚠️ Warning `the attribute version is obsolete`** au lancement de `docker compose up -d` : ce n'est pas bloquant, le déploiement fonctionne quand même. Les versions récentes de Docker Compose n'ont plus besoin de la ligne `version: "3.x"` en haut du fichier — elle peut être supprimée du `compose.yaml` pour faire disparaître le warning.

**Je ne vois que des métriques `go_...`, pas de `node_...`** : c'est normal, le endpoint `/metrics` liste d'abord les métriques internes de Go/du processus, puis les métriques `node_...` plus bas dans la page. Deux solutions :
- Scroller vers le bas dans le navigateur, ou faire `Ctrl+F` et chercher `node_cpu` ou `node_memory`
- Filtrer directement en ligne de commande :
```bash
curl -s http://192.168.1.50:9100/metrics | grep node_cpu
```

---

## Prometheus

📍 Dossier : `~/homelab/docker/monitoring/prometheus/`

Le nom `node-exporter` fonctionne comme cible (au lieu d'une IP) car les deux conteneurs sont sur le même réseau Docker `homelab` — Docker fait la résolution de nom automatiquement.

### Installation

```bash
mkdir -p ~/homelab/docker/monitoring/prometheus
cd ~/homelab/docker/monitoring/prometheus
nano prometheus.yml
```

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "raspberry"
    static_configs:
      - targets:
          - node-exporter:9100
```

```bash
nano compose.yaml
```

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - homelab

volumes:
  prometheus_data:

networks:
  homelab:
    external: true
```

```bash
docker compose up -d
docker ps
```

### Vérification

`http://192.168.1.50:9090/targets` (menu ☰ → Status → Targets) → la cible `raspberry` doit afficher **UP**.

### Résolution de problèmes rencontrés

**La page Targets est vide, aucune cible listée** — vérifier dans l'ordre :

1. **Le fichier `prometheus.yml` est-il bien monté dans le conteneur ?**
```bash
docker exec -it prometheus cat /etc/prometheus/prometheus.yml
```
Doit afficher le contenu réel du fichier. S'il est vide ou différent, le volume n'est pas monté correctement.

2. **Le YAML est-il valide ?** Attention à l'indentation (espaces, pas de tabulations) :
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "raspberry"
    static_configs:
      - targets:
          - node-exporter:9100
```

3. **Erreurs au démarrage ?**
```bash
docker logs prometheus
```

4. **Redémarrer après toute modification du fichier :**
```bash
docker compose restart
```

**Target `DOWN`** : vérifier que Prometheus et node-exporter sont bien sur le même réseau :
```bash
docker network inspect homelab
```
Les deux conteneurs doivent apparaître dans la liste.

---

## Grafana

📍 Dossier : `~/homelab/docker/monitoring/grafana/`

### Installation

```bash
mkdir -p ~/homelab/docker/monitoring/grafana
cd ~/homelab/docker/monitoring/grafana
nano compose.yaml
```

```yaml
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - homelab

volumes:
  grafana_data:

networks:
  homelab:
    external: true
```

```bash
docker compose up -d
docker ps
```

**Accès** : `http://192.168.1.50:3001` (mapping externe 3001 → port interne 3000 du conteneur).
Identifiants par défaut à la première connexion : `admin` / `admin`.

---

## Uptime Kuma

📍 Dossier : `~/homelab/docker/uptime-kuma/`

### Installation

```bash
mkdir -p ~/homelab/docker/uptime-kuma
cd ~/homelab/docker/uptime-kuma
nano compose.yaml
```

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3002:3001"
    volumes:
      - uptime-kuma_data:/app/data
    networks:
      - homelab

volumes:
  uptime-kuma_data:

networks:
  homelab:
    external: true
```

```bash
docker compose up -d
docker ps
```

**Accès** : `http://192.168.1.50:3002`

### Configuration du monitor Pi-hole
- **Type** : HTTP(s)
- **URL** : `http://pihole/admin/`
- Le nom `pihole` fonctionne comme cible car les deux conteneurs sont sur le même réseau Docker `homelab`.

### Résolution de problèmes rencontrés

**Monitor Pi-hole affiche "offline" alors que le service tourne** : cause identifiée — l'URL était en `https://pihole/admin/` alors que Pi-hole sert son interface admin en **HTTP** par défaut (pas de certificat SSL configuré dessus). Corriger l'URL en `http://pihole/admin/` résout le problème.

Si ça reste "offline" après correction :
1. Vérifier que le nom du conteneur correspond exactement au `container_name` du `compose.yaml` Pi-hole :
```bash
docker ps --format "{{.Names}}" | grep pihole
```
2. Tester la connexion directement depuis le conteneur Uptime Kuma :
```bash
docker exec -it uptime-kuma sh
wget -O- http://pihole/admin/
```
Si ça ne répond pas, vérifier que les deux conteneurs sont bien sur le réseau `homelab` :
```bash
docker network inspect homelab
```

### Notifications Discord
1. **Côté Discord** : Paramètres du salon → Intégrations → Webhooks → Nouveau webhook → copier l'URL du webhook.
2. **Côté Uptime Kuma** : Settings → Notifications → Setup Notification → type **Discord** → coller l'URL du webhook → Save.
3. Appliquer la notification à chaque monitor existant (Edit → cocher la notification Discord → Save), ou cocher "Default enabled" pour les futurs monitors.
4. Tester avec le bouton **Test** sur la page de configuration de la notification.

---

## Intégration Homepage

📍 Fichier : `~/homelab/docker/homepage/config/services.yaml`

```yaml
- Infrastructure:
    - Pi-hole:
        icon: pi-hole.png
        href: http://home-lab.local/admin
        description: DNS + bloqueur publicitaire
    - Portainer:
        icon: portainer.png
        href: https://home-lab.local:9443
        description: Gestion Docker

- Monitoring:
    - Grafana:
        icon: grafana.png
        href: http://home-lab.local:3001
        description: Tableaux de bord
    - Prometheus:
        icon: prometheus.png
        href: http://home-lab.local:9090
        description: Collecte métriques
    - Uptime Kuma:
        icon: uptime-kuma.png
        href: http://home-lab.local:3002
        description: Supervision services
```

Recharge automatique généralement, sinon :
```bash
docker restart homepage
```

---

## Vérifier les ports ouverts

Utile pour confirmer qu'un service écoute bien, ou diagnostiquer un souci d'accès.

**Avec `ss` (recommandé)** :
```bash
sudo ss -tulpn
```
`t` = TCP, `u` = UDP, `l` = en écoute, `p` = nom du processus, `n` = ports numériques

**Filtrer sur un port précis** :
```bash
sudo ss -tulpn | grep 9100
sudo ss -tulpn | grep 9090
```

**Côté Docker** — ports mappés par les conteneurs :
```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

**Depuis une autre machine du réseau**, vérifier qu'un port répond bien de l'extérieur :
```bash
nc -zv 192.168.1.50 9100
```
ou avec `nmap` :
```bash
nmap -p 9100,9090,3001,3002 192.168.1.50
```

---

## Sécurité — exposition réseau

Aucun port de la stack monitoring n'est redirigé vers Internet (pas de port forwarding sur le routeur) : tous ces services ne sont accessibles que depuis le réseau local. Pour un accès distant, passer par le VPN WireGuard déjà en place plutôt que d'ouvrir ces ports publiquement.

---

## Rappel structure générale

- Un dossier par service sous `docker/<service>/compose.yaml`
- Config versionnée sur GitHub : dépôt `aprojethome/homelab`
- Documentation en fichiers markdown par partie (ex. `03-docker.md` = install Docker/Portainer, `04-monitoring.md` = ce fichier)
