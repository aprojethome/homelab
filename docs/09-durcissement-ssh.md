# 09 - Durcissement SSH

## Objectif

SSH est la principale porte d'entrée d'administration du Raspberry Pi.

Cette étape vise à renforcer la sécurité SSH grâce à :

- une authentification par clé ;
- l'interdiction du compte root ;
- la suppression progressive des mots de passe ;
- la vérification de la configuration effective.

---

# 9.1 Sauvegarde de la configuration SSH

Avant modification :

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

Cette sauvegarde permet de revenir à la configuration précédente en cas de problème.

---

# 9.2 Vérification de la configuration utilisée

Commande :

```bash
sudo sshd -T
```

Cette commande affiche la configuration réellement appliquée par OpenSSH.

Vérification ciblée :

```bash
sudo sshd -T | grep -E "permitrootlogin|pubkeyauthentication|passwordauthentication"
```

---

# 9.3 Création d'une clé SSH

La connexion par clé est plus sécurisée qu'une connexion par mot de passe.

Création depuis le poste administrateur :

```bash
ssh-keygen -t ed25519
```

Deux fichiers sont créés :

| Fichier | Rôle |
|---|---|
| id_ed25519 | Clé privée |
| id_ed25519.pub | Clé publique |

La clé privée reste uniquement sur le poste administrateur.

---

# 9.4 Installation de la clé sur le Raspberry Pi

Commande :

```bash
ssh-copy-id alex@IP_DU_RASPBERRY
```

Exemple :

```bash
ssh-copy-id alex@192.168.1.50
```

La clé publique est ajoutée dans :

```text
~/.ssh/authorized_keys
```

---

# 9.5 Permissions SSH

Sur le Raspberry Pi :

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Ces permissions empêchent l'accès non autorisé aux clés.

---

# 9.6 Configuration SSH

Modification :

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

# 9.7 Test avant redémarrage

Avant application :

```bash
sudo sshd -t
```

Cette commande vérifie uniquement la syntaxe.

Si aucune erreur :

```bash
sudo systemctl reload ssh
```

---

# 9.8 Problème rencontré avec cloud-init

Lors de la vérification :

```bash
sudo sshd -T | grep passwordauthentication
```

Résultat inattendu :

```text
passwordauthentication yes
```

Recherche :

```bash
sudo grep -R "PasswordAuthentication" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
```

Résultat :

```text
/etc/ssh/sshd_config:PasswordAuthentication no
/etc/ssh/sshd_config.d/50-cloud-init.conf:PasswordAuthentication yes
```

---

# 9.9 Explication cloud-init

Cloud-init est un système d'initialisation utilisé sur certaines distributions Linux.

Il permet de configurer automatiquement :

- utilisateurs ;
- réseau ;
- SSH ;
- paramètres système.

Dans ce cas, un fichier cloud-init surchargeait la configuration SSH principale.

---

# 9.10 Correction

Création d'une configuration prioritaire :

```bash
sudo nano /etc/ssh/sshd_config.d/99-security.conf
```

Contenu :

```text
PasswordAuthentication no
```

Application :

```bash
sudo sshd -t
sudo systemctl reload ssh
```

---

# Résultat

SSH est maintenant configuré avec :

✅ clé SSH  
✅ accès root interdit  
✅ limitation des tentatives  
✅ suppression de l'authentification par mot de passe  
✅ configuration vérifiée avant application
