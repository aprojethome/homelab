# PARTIE 12 — Scripts de sauvegarde et de maintenance

## 12.1 Script `backup-docker.sh`

📍 Où : `~/homelab/scripts/backup-docker.sh`

Ce script effectue une sauvegarde complète en un seul passage :
1. Sauvegarde des fichiers de config (`docker/*/compose.yaml`, YAML) en excluant les secrets Pi-hole
2. Arrêt propre de chaque conteneur concerné, sauvegarde de son volume Docker, puis redémarrage
3. Vérification d'intégrité de chaque archive créée
4. Rotation des sauvegardes locales (suppression au-delà de 56 jours)
5. Copie vers la clé USB montée sur `/mnt/backup-usb`
6. Rotation des sauvegardes sur la clé USB

### Contenu complet

```bash
#!/bin/bash
set -e

USER_HOME="/home/alex"
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="$USER_HOME/homelab/backups/$DATE"
USB_DIR="/mnt/backup-usb/homelab-backups"
LOG="$USER_HOME/homelab/backups/backup.log"

mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

log "=== Début sauvegarde ==="

# 1. Config (fichiers compose.yaml, YAML) — exclut le mot de passe Pi-hole
log "Sauvegarde des fichiers de config..."
tar --exclude='*/etc-pihole/cli_pw' -czf "$BACKUP_DIR/docker-config.tar.gz" "$USER_HOME/homelab/docker"

# 2. Volumes Docker — arrêt propre avant sauvegarde pour éviter la corruption
VOLUMES=("portainer_portainer_data" "grafana_grafana_data" "prometheus_prometheus_data")
CONTAINERS=("portainer" "grafana" "prometheus")

for i in "${!VOLUMES[@]}"; do
    VOL="${VOLUMES[$i]}"
    CONT="${CONTAINERS[$i]}"

    if docker volume inspect "$VOL" >/dev/null 2>&1; then
        log "Arrêt de $CONT pour sauvegarde propre..."
        docker stop "$CONT" >/dev/null 2>&1 || true

        docker run --rm \
            -v "$VOL":/data \
            -v "$BACKUP_DIR":/backup \
            alpine tar czf "/backup/$VOL.tar.gz" /data

        docker start "$CONT" >/dev/null 2>&1 || true
        log "Volume $VOL sauvegardé, $CONT redémarré."
    else
        log "Volume $VOL introuvable, ignoré."
    fi
done

# 3. Vérification d'intégrité des archives
log "Vérification des archives..."
for f in "$BACKUP_DIR"/*.tar.gz; do
    if tar tzf "$f" >/dev/null 2>&1; then
        log "OK: $f"
    else
        log "ERREUR: archive corrompue -> $f"
    fi
done

# 4. Rotation locale — garde 8 semaines (56 jours)
log "Nettoyage des sauvegardes locales de plus de 56 jours..."
find "$USER_HOME/homelab/backups" -maxdepth 1 -type d -mtime +56 -exec rm -rf {} \;

# 5. Copie vers la clé USB (si montée)
if mountpoint -q /mnt/backup-usb; then
    log "Copie vers la clé USB..."
    mkdir -p "$USB_DIR"
    rsync -rlt --no-owner --no-group "$BACKUP_DIR" "$USB_DIR/"

    log "Nettoyage USB (plus de 56 jours)..."
    find "$USB_DIR" -maxdepth 1 -type d -mtime +56 -exec rm -rf {} \;
else
    log "ATTENTION: clé USB non montée, copie externe ignorée."
fi

log "=== Sauvegarde terminée ==="
```

### Points techniques importants

- **`--exclude='*/etc-pihole/cli_pw'`** : ce fichier est un mot de passe généré par Pi-hole, appartenant à `root`. Il n'est ni lisible par `alex`, ni utile à sauvegarder (régénérable).
- **Noms de volumes préfixés** : Docker Compose préfixe chaque volume nommé avec le nom du dossier du projet (`grafana_grafana_data` et non `grafana_data`). Toujours vérifier avec `docker volume ls` avant de modifier le script.
- **`rsync -rlt --no-owner --no-group`** : la clé USB est formatée en exFAT, qui ne supporte pas les permissions Unix (propriétaire/groupe). Sans ces options, `rsync` échoue avec une erreur `chown: Operation not permitted` quand le script tourne en `sudo`.
- **Le script doit être lancé en `sudo`** pour pouvoir arrêter/démarrer les conteneurs et lire le dossier `etc-pihole/`.

### Rendre exécutable et tester manuellement

```bash
chmod +x ~/homelab/scripts/backup-docker.sh
sudo ~/homelab/scripts/backup-docker.sh
cat ~/homelab/backups/backup.log
```

---

## 12.2 Script `maintenance.sh`

📍 Où : `~/homelab/scripts/maintenance.sh`

```bash
#!/bin/bash
echo "Nettoyage Docker"
docker system prune -f

echo "Mise à jour du système"
sudo apt update
sudo apt upgrade -y
```

```bash
chmod +x ~/homelab/scripts/maintenance.sh
```

**Ce script est volontairement lancé manuellement, pas en cron** : `apt upgrade -y` applique les mises à jour sans confirmation, il vaut mieux être présent pour vérifier que tout redémarre correctement ensuite plutôt qu'en pleine nuit sans surveillance.

`docker system prune -f` supprime les images/conteneurs/réseaux inutilisés, **mais pas les volumes** par défaut — les données ne sont pas touchées.
