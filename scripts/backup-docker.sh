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

# 1. Config (fichiers compose.yaml, YAML)
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
