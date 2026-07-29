# 10 - Nettoyage des services Linux inutilisés

## Objectif

Un serveur sécurisé doit limiter le nombre de services actifs.

Chaque service réseau supplémentaire représente une surface d'attaque potentielle.

---

# 10.1 Identification des services

Commande utilisée :

```bash
sudo netstat -tulpn
```

Un service RPC était présent :

```text
Port 111
```

Service associé :

```text
rpcbind
```

---

# 10.2 Analyse de rpcbind

rpcbind est utilisé pour les communications RPC.

Il est principalement nécessaire pour :

- NFS ;
- certains services de partage Linux.

---

# 10.3 Vérification de l'utilisation NFS

Recherche de montages NFS :

```bash
mount | grep nfs
```

Résultat :

```text
Aucun partage NFS actif.
```

Le service n'était donc pas nécessaire.

---

# 10.4 Désactivation de rpcbind

Première commande :

```bash
sudo systemctl disable --now rpcbind
```

Le système indiquait que le socket restait actif :

```text
rpcbind.socket still active
```

---

# 10.5 Désactivation du socket systemd

rpcbind utilisait l'activation par socket.

Commande :

```bash
sudo systemctl disable --now rpcbind.socket
```

---

# 10.6 Vérification finale

Contrôle du port 111 :

```bash
sudo netstat -tulpn | grep 111
```

Résultat :

```text
Aucune sortie.
```

Le port RPC n'est plus exposé.

---

# Conclusion

Le nettoyage a permis :

✅ suppression d'un service inutile  
✅ fermeture du port 111  
✅ réduction de la surface d'attaque  
✅ configuration plus adaptée à un serveur Docker Homelab
