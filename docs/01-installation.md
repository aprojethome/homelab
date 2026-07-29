
# Installation du Raspberry Pi

## Système

- Raspberry Pi 400
- Raspberry Pi OS Lite 64 bits

---

## Première connexion SSH

La première connexion au Raspberry Pi s'effectue depuis un PC Windows à l'aide de MobaXterm ou d'un terminal SSH.

Commande :

```bash
ssh utilisateur@192.168.50.50
```

> **Remarque :** Le nom d'utilisateur et l'adresse IP utilisés dans cette documentation sont des exemples.

---

## Mise à jour du système

Mettre à jour la liste des paquets :

```bash
sudo apt update
```

Installer les mises à jour disponibles :

```bash
sudo apt upgrade -y
```

Redémarrer le système :

```bash
sudo reboot
```

---

## Vérification du réseau

Vérifier la configuration IPv4 :

```bash
nmcli connection show netplan-wlan0-HomeNetwork | grep ipv4
```

Résultat attendu :

- Le Raspberry Pi obtient automatiquement une adresse IP via DHCP.
- Une réservation DHCP sera configurée sur la box Internet afin de lui attribuer toujours la même adresse IP.
