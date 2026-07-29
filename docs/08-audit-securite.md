# 08 - Audit sécurité du Raspberry Pi

## Objectif

Après la mise en place des premières mesures de sécurité, un audit a été réalisé afin d'identifier :

- les services accessibles sur le réseau ;
- les ports ouverts ;
- les services inutiles ;
- les éléments augmentant la surface d'attaque.

L'objectif est de conserver uniquement les services nécessaires au fonctionnement du serveur.

---

# 8.1 Vérification des ports ouverts

Commande utilisée :

```bash
sudo netstat -tulpn
```

Cette commande permet d'afficher :

- les ports TCP en écoute ;
- les ports UDP ouverts ;
- les programmes associés ;
- les processus utilisant les ports.

---

# 8.2 Analyse initiale

Lors de l'audit initial, les services suivants étaient visibles :

| Port | Service | Fonction |
|---|---|---|
| 22/tcp | SSH | Administration distante |
| 111/tcp | rpcbind | Services RPC/NFS |
| 111/udp | rpcbind | Services RPC/NFS |
| 5353/udp | Avahi | Découverte réseau mDNS |

---

# 8.3 Analyse de sécurité

## SSH

SSH est nécessaire pour administrer le Raspberry Pi à distance.

Mesures appliquées :

- interdiction de connexion root directe ;
- utilisation prévue d'une clé SSH ;
- limitation des tentatives de connexion ;
- préparation de la désactivation du mot de passe.

---

## rpcbind

Le service rpcbind était actif sur le port 111.

Ce service est principalement utilisé pour :

- NFS ;
- RPC Linux ;
- certains services de partage réseau.

Une vérification a été réalisée :

```bash
mount | grep nfs
```

Résultat :

```text
Aucun montage NFS actif.
```

Le service n'était donc pas nécessaire.

---

# 8.4 Vérification des services actifs

Commande :

```bash
systemctl list-unit-files
```

Permet d'identifier les services activés automatiquement au démarrage.

---

# 8.5 Résultat de l'audit

Après analyse :

Services conservés :

| Service | Utilité |
|---|---|
| SSH | Administration serveur |
| Docker | Services applicatifs |
| WireGuard | Accès VPN |

Services analysés puis désactivés :

| Service | Raison |
|---|---|
| rpcbind | Aucun besoin NFS |

---

# Conclusion

L'audit a permis de réduire la surface d'exposition réseau du Raspberry Pi.

Le principe appliqué :

> Un serveur ne doit exposer que les services réellement utilisés.
