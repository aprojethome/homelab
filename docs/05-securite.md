# 05 - Sécurisation du Raspberry Pi

## Objectif

Renforcer la sécurité du Raspberry Pi avant l'installation des services Docker.

Cette étape a pour objectifs :

- protéger le serveur avec un pare-feu ;
- sécuriser l'accès SSH ;
- mettre en place une authentification par clé ;
- limiter les services exposés ;
- protéger contre les tentatives de connexion répétées ;
- appliquer les bonnes pratiques Linux.

---

# 5.1 Mise à jour du système

Avant toute configuration de sécurité, le système est mis à jour.

Commandes :

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

Vérification des mises à jour restantes :

```bash
sudo apt list --upgradable
```

Résultat attendu :

```text
Aucun paquet important en attente de mise à jour.
```

---

# 5.2 Installation des outils de sécurité

Installation :

```bash
sudo apt install -y ufw fail2ban unattended-upgrades apt-listchanges
```

## Rôle des outils

| Outil | Fonction |
|---|---|
| UFW | Pare-feu Linux simplifié |
| Fail2ban | Protection contre les tentatives de connexion répétées |
| unattended-upgrades | Installation automatique des mises à jour de sécurité |
| apt-listchanges | Informations sur les changements de paquets |

---

# 5.3 Configuration du pare-feu UFW

## Principe

Le pare-feu applique une politique restrictive :

- toutes les connexions entrantes sont bloquées par défaut ;
- seuls les services nécessaires sont autorisés.

---

## Configuration des règles par défaut

Bloquer les connexions entrantes :

```bash
sudo ufw default deny incoming
```

Autoriser les connexions sortantes :

```bash
sudo ufw default allow outgoing
```

---

## Autorisation SSH

Avant l'activation du pare-feu, SSH doit être autorisé afin d'éviter de perdre l'accès distant.

Commande :

```bash
sudo ufw allow OpenSSH
```

Cela autorise :

```text
22/tcp
```

---

## Activation du pare-feu

```bash
sudo ufw enable
```

---

## Vérification

```bash
sudo ufw status verbose
```

Résultat attendu :

```text
Status: active

Default:
deny (incoming)
allow (outgoing)
```

---

# 5.4 Gestion des ports réseau

Les ports sont ouverts uniquement lorsqu'un service est installé.

| Service | Port | Protocole |
|---|---|---|
| SSH | 22 | TCP |
| Pi-hole DNS | 53 | TCP / UDP |
| Pi-hole Web | 80 | TCP |
| HTTPS | 443 | TCP |
| Grafana | 3000 | TCP |
| Uptime Kuma | 3001 | TCP |
| Prometheus | 9090 | TCP |
| Portainer | 9443 | TCP |
| WireGuard | 51820 | UDP |

Principe appliqué :

> Aucun port n'est ouvert sans service associé.

---

# 5.5 Installation et configuration Fail2ban

## Objectif

Fail2ban surveille les journaux système et bloque automatiquement les adresses IP effectuant trop de tentatives de connexion.

Installation :

```bash
sudo apt install fail2ban -y
```

---

## Création de la configuration locale

Création du fichier :

```bash
sudo nano /etc/fail2ban/jail.local
```

Configuration :

```ini
[DEFAULT]

bantime = 1h
findtime = 10m
maxretry = 5


[sshd]

enabled = true
port = ssh
logpath = %(sshd_log)s
backend = systemd
```

---

## Redémarrage du service

```bash
sudo systemctl restart fail2ban
```

Activation au démarrage :

```bash
sudo systemctl enable fail2ban
```

---

## Vérification

État général :

```bash
sudo fail2ban-client status
```

Protection SSH :

```bash
sudo fail2ban-client status sshd
```

Résultat attendu :

```text
Le jail sshd est actif.
```

---

# 5.6 Authentification SSH par clé

## Objectif

Remplacer l'authentification SSH par mot de passe par une authentification utilisant une clé cryptographique.

Une clé SSH contient deux éléments :

| Élément | Emplacement |
|---|---|
| Clé privée | Poste administrateur |
| Clé publique | Raspberry Pi |

La clé privée ne doit jamais être copiée sur le serveur.

---

# Création d'une clé SSH

Depuis le poste administrateur :

```bash
ssh-keygen -t ed25519
```

Fichiers générés :

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

---

# Ajout de la clé publique sur le Raspberry Pi

Commande :

```bash
ssh-copy-id alex@IP_DU_RASPBERRY
```

Exemple :

```bash
ssh-copy-id alex@192.168.1.50
```

La clé est ajoutée dans :

```text
~/.ssh/authorized_keys
```

---

# Vérification des permissions SSH

Sur le Raspberry Pi :

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

# Connexion avec MobaXterm

La connexion SSH utilise :

- utilisateur : `alex`
- adresse IP du Raspberry Pi
- clé privée générée précédemment

La connexion doit fonctionner sans saisir le mot de passe.

---

# 5.7 Durcissement SSH

## Sauvegarde de la configuration

Avant modification :

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

---

## Modification SSH

Éditer :

```bash
sudo nano /etc/ssh/sshd_config
```

Paramètres appliqués :

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
MaxAuthTries 3
LoginGraceTime 30
```

---

## Test de configuration

Avant d'appliquer :

```bash
sudo sshd -t
```

Si aucune erreur n'apparaît :

```bash
sudo systemctl reload ssh
```

---

## Vérification finale SSH

```bash
sudo sshd -T | grep -E "permitrootlogin|pubkeyauthentication|passwordauthentication"
```

Résultat attendu :

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
```

---

# 5.8 Gestion du cas cloud-init

Sur Raspberry Pi OS récent, cloud-init peut ajouter automatiquement des fichiers de configuration SSH.

Recherche :

```bash
sudo grep -R "PasswordAuthentication" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
```

Si un fichier force :

```text
PasswordAuthentication yes
```

Créer une configuration locale :

```bash
sudo nano /etc/ssh/sshd_config.d/99-security.conf
```

Ajouter :

```text
PasswordAuthentication no
```

Puis appliquer :

```bash
sudo sshd -t
sudo systemctl reload ssh
```

---

# 5.9 Activation des mises à jour automatiques

Configuration :

```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Choisir :

```text
Yes
```

Vérification :

```bash
systemctl status unattended-upgrades
```

---

# 5.10 Outils de surveillance système

Installation :

```bash
sudo apt install -y htop ncdu
```

Utilisation :

Voir les ressources système :

```bash
htop
```

Analyser le stockage :

```bash
ncdu /
```

---

# 5.11 Vérification finale sécurité

## Pare-feu

```bash
sudo ufw status
```

Résultat attendu :

```text
Status: active
```

---

## SSH

```bash
systemctl status ssh
```

Résultat attendu :

```text
active (running)
```

---

## Fail2ban

```bash
systemctl status fail2ban
```

Résultat attendu :

```text
active (running)
```

---

## Ports ouverts

```bash
sudo netstat -tulpn
```

Objectif :

Afficher uniquement les services nécessaires.

---

# Résultat

Le Raspberry Pi possède maintenant une base de sécurité renforcée :

✅ Pare-feu UFW actif  
✅ Protection Fail2ban  
✅ Authentification SSH par clé  
✅ Connexion root SSH interdite  
✅ Services réseau limités  
✅ Mises à jour automatiques activées  
✅ Serveur prêt pour l'installation Docker
