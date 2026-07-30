# PARTIE 13 — Stratégie de sauvegarde complète

## 13.1 Pourquoi

Une carte SD peut se corrompre à tout moment. Sans sauvegarde, une panne = perte de toute la configuration et de l'historique (statistiques Pi-hole, dashboards Grafana, historique Uptime Kuma, données Prometheus).

Stratégie à trois niveaux :
- **Configuration** (`compose.yaml`, YAML) → versionnée dans Git.
- **Volumes Docker** (bases de données, historiques) → sauvegardés localement puis copiés sur un support externe.
- **Image complète de la carte SD** → à faire manuellement de temps en temps, avant une grosse modification.

## 13.2 Préparer les dossiers

📍 Où : terminal SSH, dans `~/homelab`

```bash
mkdir -p backups scripts
```

## 13.3 Préparer la clé USB externe

📍 Où : terminal SSH

**Identifier la clé branchée :**
```bash
lsblk
```

**Formater en exFAT** (lisible aussi sur Windows/Mac, pas de limite de taille de fichier) :
```bash
sudo apt install exfatprogs -y
sudo umount /dev/sda1 2>/dev/null
sudo mkfs.exfat -n BACKUP-HOMELAB /dev/sda1
```
⚠️ Bien vérifier le nom du périphérique avant exécution (`/dev/sda1` ≠ la carte SD `/dev/mmcblk0`).

**Créer le point de montage et récupérer l'UUID :**
```bash
sudo mkdir -p /mnt/backup-usb
sudo blkid /dev/sda1
```

**Montage automatique au démarrage** — éditer `/etc/fstab` :
```bash
sudo nano /etc/fstab
```
Ajouter (avec l'UUID réel) :
```
UUID=xxxx-xxxx  /mnt/backup-usb  exfat  defaults,nofail  0  0
```
`nofail` garantit que le Pi démarre normalement même si la clé n'est pas branchée.

**Monter immédiatement sans redémarrer :**
```bash
sudo mount -a
df -h | grep backup-usb
```

## 13.4 Script de sauvegarde

Voir `docs/12-sauvegarde-script.md` pour le détail technique de `backup-docker.sh`. Il sauvegarde en un seul passage : la config Git, les 3 volumes Docker (Portainer, Grafana, Prometheus), avec vérification d'intégrité, rotation automatique et copie vers la clé USB.

## 13.5 Automatiser avec Cron

Le script nécessite `sudo` (arrêt/démarrage des conteneurs, lecture de `etc-pihole/`) — la tâche cron doit donc être ajoutée au **crontab root**, pas à celui d'un utilisateur normal :

```bash
sudo crontab -e
```
Ajouter :
```
0 3 * * 0 /home/alex/homelab/scripts/backup-docker.sh
```
(Format cron : minute · heure · jour du mois · mois · jour de la semaine — `0` = dimanche, exécution chaque dimanche à 3h du matin.)

Vérifier que la tâche est bien enregistrée :
```bash
sudo crontab -l
```

## 13.6 Tester une restauration

Une sauvegarde qui n'a jamais été testée n'est pas une sauvegarde fiable. Test effectué et validé :

```bash
mkdir -p /tmp/test-restore
tar xzf ~/homelab/backups/2026-07-30/grafana_grafana_data.tar.gz -C /tmp/test-restore
ls /tmp/test-restore/data
```
Résultat attendu : `csv  grafana.db  pdf  plugins  png  unified-search` — confirme que l'archive contient bien la base de données et les dashboards Grafana, exploitable en cas de restauration réelle.

Nettoyage après test :
```bash
rm -rf /tmp/test-restore
```

## 13.7 Gestion de la clé USB au quotidien

Compromis retenu : **la clé reste branchée en permanence** pour que le cron hebdomadaire fonctionne sans intervention manuelle. Pour conserver une vraie protection contre un incident physique touchant le Pi (surtension, dégât des eaux), il est recommandé de :

1. Démonter proprement la clé de temps en temps (une fois par mois par exemple) :
```bash
sudo umount /mnt/backup-usb
```
2. La débrancher et faire une copie manuelle vers un autre support (PC, autre disque, cloud).
3. La rebrancher et la remonter :
```bash
sudo mount -a
```

Si la clé est débranchée au moment du cron du dimanche, le script ne bloque pas : il log `"clé USB non montée, copie externe ignorée"` et continue normalement pour le reste de la sauvegarde.

## 13.8 Vérifier l'espace disque

📍 Où : terminal SSH

```bash
docker system df
df -h
```

## 13.9 Récapitulatif de ce qui est en place

- ✅ Config (`compose.yaml`, YAML) → versionnée dans Git
- ✅ Volumes Docker (Grafana, Prometheus, Portainer) → sauvegardés avec arrêt/redémarrage propre
- ✅ Copie automatique vers clé USB externe (exFAT, sans permissions Unix)
- ✅ Rotation automatique (56 jours, local + USB)
- ✅ Vérification d'intégrité des archives après chaque sauvegarde
- ✅ Automatisation hebdomadaire via cron root (dimanche 3h)
- ✅ Restauration testée et validée manuellement
