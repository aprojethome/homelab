# Sécurisation SSH Raspberry Pi

## Documentation complète de connexion, configuration et sécurisation SSH

---

# 1. Objectif

Cette documentation décrit la mise en place d'une connexion SSH sécurisée entre :

* Un PC Windows avec PowerShell et MoBaXterm.
* Un Raspberry Pi sous Debian.
* Un utilisateur Linux nommé `alex`.

Objectifs :

* Vérifier la connexion SSH.
* Corriger les problèmes de connexion.
* Activer temporairement l'accès par mot de passe.
* Installer une clé SSH ED25519.
* Tester la connexion par clé.
* Désactiver l'accès par mot de passe.
* Conserver une procédure de dépannage.

---

# 2. Informations de connexion

## Raspberry Pi

Utilisateur :

```text
alex
```

Adresse IP :

```text
192.168.1.183
```

Port SSH :

```text
22
```

Commande de connexion :

```bash
ssh alex@192.168.1.183
```

---

# 3. Premier test depuis Windows PowerShell

Commande utilisée :

```powershell
ssh -v alex@192.168.1.183
```

L'option :

```text
-v
```

permet d'afficher les informations détaillées de connexion SSH.

## Résultat réseau positif

Les lignes suivantes indiquent que le Raspberry répond :

```text
Connecting to 192.168.1.183 port 22
Connection established
```

Le serveur détecté :

```text
Remote software version OpenSSH_10.0p2 Debian
```

Cela confirme :

* L'adresse IP est correcte.
* Le port SSH 22 est ouvert.
* Le serveur SSH fonctionne.

---

# 4. Première connexion SSH

Lors de la première connexion SSH :

```text
The authenticity of host '192.168.1.183' can't be established.
```

SSH demande :

```text
Are you sure you want to continue connecting?
```

Réponse :

```text
yes
```

La clé du serveur est enregistrée dans :

```text
C:\Users\alexa\.ssh\known_hosts
```

Message obtenu :

```text
Warning: Permanently added '192.168.1.183' (ED25519)
```

---

# 5. Erreur rencontrée : Host key verification failed

Erreur :

```text
Host key verification failed.
```

Cause :

La clé du serveur SSH n'avait pas encore été acceptée.

Solution :

Relancer :

```bash
ssh alex@192.168.1.183
```

Puis accepter :

```text
yes
```

---

# 6. Erreur initiale d'authentification

Message obtenu :

```text
Authentications that can continue: publickey
```

Puis :

```text
Permission denied (publickey)
```

Analyse :

Le serveur SSH fonctionnait mais n'acceptait que les clés SSH.

La clé publique du PC Windows n'était pas encore installée sur le Raspberry.

---

# 7. Vérification des clés SSH Windows

Commande :

```powershell
dir $env:USERPROFILE\.ssh
```

Clés présentes :

```text
id_ed25519
id_ed25519.pub
```

Emplacement :

```text
C:\Users\alexa\.ssh\
```

## Clé privée

Fichier :

```text
id_ed25519
```

⚠️ Ne doit jamais être copiée ou envoyée.

## Clé publique

Fichier :

```text
id_ed25519.pub
```

Peut être installée sur le Raspberry.

---

# 8. Lecture de la clé publique

Commande PowerShell :

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

Résultat :

```text
ssh-ed25519 AAAAxxxxxxxxxxxxxxxx
```

Cette ligne complète correspond à la clé publique.

---

# 9. Activation temporaire du mot de passe SSH

Afin de récupérer l'accès, l'authentification par mot de passe a été activée temporairement.

Vérification :

```bash
sudo sshd -T | grep passwordauthentication
```

Résultat :

```text
passwordauthentication yes
```

Redémarrage du service SSH :

```bash
sudo systemctl restart ssh
```

Vérification :

```bash
sudo systemctl status ssh
```

Résultat attendu :

```text
Active: active (running)
```

---

# 10. Connexion avec MoBaXterm

Configuration utilisée :

| Paramètre       | Valeur        |
| --------------- | ------------- |
| Protocole       | SSH           |
| Adresse serveur | 192.168.1.183 |
| Port            | 22            |
| Utilisateur     | alex          |

La connexion MoBaXterm fonctionne avec le mot de passe.

Cette connexion est utilisée pour installer la clé SSH.

---

# 11. Installation de la clé publique sur le Raspberry

Créer le dossier SSH :

```bash
mkdir -p ~/.ssh
```

Protection du dossier :

```bash
chmod 700 ~/.ssh
```

Création du fichier des clés autorisées :

```bash
nano ~/.ssh/authorized_keys
```

Coller la clé publique :

```text
ssh-ed25519 AAAAxxxxxxxxxxxxxxxx
```

Sauvegarde Nano :

```text
CTRL + O
Entrée
CTRL + X
```

Protection du fichier :

```bash
chmod 600 ~/.ssh/authorized_keys
```

---

# 12. Test de connexion par clé SSH

Depuis PowerShell :

```powershell
ssh -v alex@192.168.1.183
```

Résultat attendu :

```text
Offering public key:
C:\Users\alexa\.ssh\id_ed25519
```

Puis :

```text
Authenticated to 192.168.1.183 using "publickey"
```

La connexion doit fonctionner sans demander de mot de passe.

---

# 13. Vérification de la configuration SSH active

Commande :

```bash
sudo sshd -T -C user=alex,addr=192.168.1.183,host=localhost
```

Vérifications :

Clé publique :

```text
pubkeyauthentication yes
```

Méthode d'authentification :

```text
authenticationmethods any
```

Pendant les tests :

```text
passwordauthentication yes
```

---

# 14. Configuration finale sécurisée

Modifier le fichier :

```bash
sudo nano /etc/ssh/sshd_config
```

Configuration finale :

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
```

Sauvegarder puis redémarrer SSH :

```bash
sudo systemctl restart ssh
```

---

# 15. Test final

Depuis Windows :

```powershell
ssh alex@192.168.1.183
```

Résultat attendu :

* Connexion automatique.
* Aucun mot de passe demandé.
* Authentification par clé ED25519.

---

# 16. Commandes de dépannage SSH

Tester la configuration :

```bash
sudo sshd -t
```

Afficher la configuration active :

```bash
sudo sshd -T
```

Configuration pour un utilisateur précis :

```bash
sudo sshd -T -C user=alex,addr=192.168.1.183,host=localhost
```

Voir les logs SSH :

```bash
sudo journalctl -u ssh
```

État du service :

```bash
sudo systemctl status ssh
```

Redémarrer SSH :

```bash
sudo systemctl restart ssh
```

---

# 17. Résumé final

| Élément                        | État |
| ------------------------------ | ---- |
| Raspberry accessible en SSH    | ✅    |
| Adresse IP vérifiée            | ✅    |
| MoBaXterm configuré            | ✅    |
| PowerShell SSH testé           | ✅    |
| Clé ED25519 Windows disponible | ✅    |
| Clé publique installée         | ✅    |
| Connexion par clé testée       | ✅    |
| Mot de passe désactivé         | ✅    |

---

# 18. Notes importantes

Toujours garder une session SSH ouverte pendant les modifications.

Avant de désactiver les mots de passe :

1. Tester une nouvelle connexion.
2. Vérifier que la clé fonctionne.
3. Garder une session de secours active.
4. Fermer les anciennes connexions uniquement après validation.

## Emplacement des clés

Clé privée sur le PC Windows :

```text
C:\Users\alexa\.ssh\id_ed25519
```

Clé publique stockée sur le Raspberry :

```text
/home/alex/.ssh/authorized_keys
```

⚠️ La clé privée ne doit jamais être copiée sur le Raspberry ni publiée.

---

# Fin du document
