# Architecture réseau

> ⚠️ **Remarque :** Les adresses IP, noms d'hôtes et captures d'écran présents dans cette documentation sont fictifs et utilisés uniquement à des fins de démonstration. L'infrastructure réelle utilise une configuration différente.

---

# Objectif

Mettre en place un Homelab sur un Raspberry Pi 400 afin d'apprendre :

- Administration Linux
- Réseau TCP/IP
- DNS
- Docker
- Sécurisation d'un serveur
- Supervision et monitoring
- VPN
- Documentation technique

---

# Schéma réseau

```text
                    Internet
                        │
                        │
              Box Internet (Routeur)
                 192.168.50.1
                        │
                        │
             Réseau LAN 192.168.50.0/24
                        │
        ┌───────────────┴───────────────┐
        │                               │
    PC Windows                    Raspberry Pi 400
 (Administration)                  homelab-pi
                                       │
                                 192.168.50.50
                                       │
                                Docker Engine
                                       │
      ┌──────────────┬──────────────┬──────────────┐
      │              │              │              │
   Pi-hole       Portainer      Homepage     WireGuard
      │
      ├── Prometheus
      ├── Grafana
      └── Uptime Kuma
```

---

# Plan d'adressage

| Équipement | Adresse IP | Rôle |
|------------|------------|------|
| Box Internet | 192.168.50.1 | Routeur, passerelle, DHCP |
| Raspberry Pi | 192.168.50.50 | Serveur Homelab |
| Réseau local | 192.168.50.0/24 | Réseau privé |

---

# Réservation DHCP

Le Raspberry Pi utilise une **réservation DHCP** configurée sur la box Internet.

Cette méthode permet :

- d'obtenir toujours la même adresse IP ;
- de faciliter l'administration du réseau ;
- d'éviter une configuration IP statique directement sur le Raspberry Pi.

---

# Services déployés

| Service | Fonction |
|----------|----------|
| Pi-hole | Serveur DNS et blocage des publicités |
| Docker | Exécution des conteneurs |
| Portainer | Gestion des conteneurs Docker |
| Homepage | Tableau de bord des services |
| Prometheus | Collecte des métriques |
| Grafana | Visualisation des métriques |
| Uptime Kuma | Supervision des services |
| WireGuard | Accès VPN sécurisé |

---

# Ports principaux

| Service | Port |
|----------|------|
| SSH | 22 |
| Pi-hole | 80 / 443 / 53 |
| Portainer | 9000 |
| Homepage | 3000 |
| Grafana | 3000 (via reverse proxy si nécessaire) |
| Prometheus | 9090 |
| Uptime Kuma | 3001 |
| WireGuard | 51820/UDP |

> **Remarque :** Certains services utilisent les mêmes ports. Ils seront configurés pour éviter les conflits (ports différents ou reverse proxy).

---

# Architecture Docker

```text
Docker
│
├── Pi-hole
├── Portainer
├── Homepage
├── Prometheus
├── Grafana
├── Uptime Kuma
└── WireGuard
```

---

# Flux DNS

```text
Ordinateur
      │
      ▼
Pi-hole (192.168.50.50)
      │
      ▼
DNS public (Cloudflare ou Quad9)
      │
      ▼
Internet
```
