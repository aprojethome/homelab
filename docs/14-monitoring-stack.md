# PARTIE 14 — Stack de monitoring (node-exporter, Prometheus, Grafana, Uptime Kuma)

## 14.1 node-exporter

📍 Où : `~/homelab/docker/monitoring/node-exporter/compose.yaml`

Expose les métriques système brutes du Raspberry Pi (CPU, mémoire, disque...) sur le port 9100.

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

Vérification : `http://192.168.1.50:9100/metrics` doit afficher une longue liste de métriques `node_...` (après les métriques internes `go_...` en début de page).

## 14.2 Prometheus

📍 Où : `~/homelab/docker/monitoring/prometheus/`

**`prometheus.yml`** — config de collecte :
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "raspberry"
    static_configs:
      - targets:
          - node-exporter:9100
```

Le nom `node-exporter` fonctionne comme cible (au lieu d'une IP) car les deux conteneurs sont sur le même réseau Docker `homelab` — Docker fait la résolution de nom automatiquement.

**`compose.yaml`** :
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

Vérification de la collecte : `http://192.168.1.50:9090/targets` → la cible `raspberry` doit afficher **UP**.

## 14.3 Grafana

📍 Où : `~/homelab/docker/monitoring/grafana/compose.yaml`

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

Accès : `http://192.168.1.50:3001` (mapping externe 3001 → port interne 3000 du conteneur). Identifiants par défaut à la première connexion : `admin` / `admin`.

## 14.4 Uptime Kuma

📍 Où : `~/homelab/docker/uptime-kuma/compose.yaml`

Accès : `http://192.168.1.50:3002`

### Configuration du monitor Pi-hole

- **Type** : HTTP(s)
- **URL** : `http://pihole/admin/` — attention, **HTTP et non HTTPS**, Pi-hole sert son interface admin en HTTP par défaut. Utiliser `https://` sur une interface qui n'a pas de certificat provoque un statut "offline" alors que le service tourne normalement.
- Le nom `pihole` fonctionne car les deux conteneurs sont sur le même réseau Docker `homelab`.

### Notifications Discord

1. **Côté Discord** : Paramètres du salon → Intégrations → Webhooks → Nouveau webhook → copier l'URL du webhook.
2. **Côté Uptime Kuma** : Settings → Notifications → Setup Notification → type **Discord** → coller l'URL du webhook → Save.
3. Appliquer la notification à chaque monitor existant (Edit → cocher la notification Discord → Save), ou cocher "Default enabled" pour les futurs monitors.
4. Tester avec le bouton **Test** sur la page de configuration de la notification.

## 14.5 Intégration Homepage

📍 Où : `~/homelab/docker/homepage/config/services.yaml`

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

## 14.6 Sécurité — exposition réseau

Aucun port de la stack monitoring n'est redirigé vers Internet (pas de port forwarding sur le routeur) : tous ces services ne sont accessibles que depuis le réseau local. Pour un accès distant, passer par le VPN WireGuard déjà en place plutôt que d'ouvrir ces ports publiquement.
