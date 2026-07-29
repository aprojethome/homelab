Installation et organisation Docker
Objectif
Installation et préparation de Docker pour le Homelab Raspberry Pi.
Objectifs :
Installer Docker Engine
Installer Docker Compose
Utiliser les conteneurs
Gérer les volumes persistants
Préparer les services Homelab
Services prévus : Pi-hole, Portainer, Homepage, Grafana, Prometheus, Uptime Kuma, VPN (WireGuard).
Installation des dépendances
📍 Où : terminal SSH sur le Raspberry Pi
Mise à jour du système :
```bash
sudo apt update
```
Installation des dépendances :
```bash
sudo apt install -y ca-certificates curl gnupg
```
Installation de la clé Docker
Création du dossier des clés :
```bash
sudo install -m 0755 -d /etc/apt/keyrings
```
Ajout de la clé officielle Docker :
```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
Vérification :
```bash
ls -l /etc/apt/keyrings/docker.gpg
```
Ajout du dépôt Docker officiel
```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian \
$(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
Mise à jour :
```bash
sudo apt update
```
Installation Docker
```bash
sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```
Vérification Docker
```bash
docker --version
```
Résultat attendu : `Docker version 28.x.x`
Test Docker
```bash
sudo docker run hello-world
```
Résultat attendu : `Hello from Docker!`
Ajouter l'utilisateur Docker
Remplace `TON_UTILISATEUR` par ton vrai nom d'utilisateur SSH (utilisé partout dans ce document) :
```bash
sudo usermod -aG docker TON_UTILISATEUR
```
Reconnexion SSH
Quitter la session :
```bash
exit
```
Connexion (adresse fictive d'exemple `192.168.1.50` — remplace par la tienne en local, ne jamais mettre ta vraie IP dans ce que tu publies sur GitHub) :
```bash
ssh TON_UTILISATEUR@192.168.1.50
```
Vérification Docker sans sudo
```bash
docker ps
```
Résultat attendu : en-tête `CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS`
Vérification Docker Compose
```bash
docker compose version
```
Résultat attendu : `Docker Compose version v2.x.x`
Créer le réseau Docker partagé (étape indispensable)
Tous les fichiers `compose.yaml` de ce Homelab (Portainer, Pi-hole, Homepage, Grafana, Prometheus, Uptime Kuma, WireGuard) référencent un réseau nommé `homelab` en `external: true`, ce qui veut dire « ce réseau doit déjà exister ». Il faut donc le créer une seule fois, maintenant, avant de lancer le moindre `docker compose up -d` :
```bash
docker network create homelab
```
Vérifier qu'il existe :
```bash
docker network ls
```
Tu dois voir une ligne `homelab` avec le driver `bridge`. Sans cette étape, le premier service que tu essaieras de démarrer plantera avec une erreur `network homelab declared as external, but could not be found`.
Organisation Homelab Docker
Création du dossier principal (chemin unifié pour tout le document : `~/homelab/docker`) :
```bash
mkdir -p ~/homelab/docker
cd ~/homelab/docker
```
Structure prévue :
```
homelab/
└── docker/
    ├── pihole/
    ├── portainer/
    ├── homepage/
    ├── monitoring/
    │   ├── node-exporter/
    │   ├── prometheus/
    │   └── grafana/
    ├── uptime-kuma/
    └── wireguard/
```
Commandes Docker utiles
Images
```bash
docker images                  # Lister les images
docker pull NOM_IMAGE           # Télécharger une image
docker rmi NOM_IMAGE             # Supprimer une image
```
Conteneurs
```bash
docker ps                       # Lister les conteneurs actifs
docker ps -a                    # Lister tous les conteneurs
docker start NOM_CONTENEUR      # Démarrer un conteneur
docker stop NOM_CONTENEUR       # Arrêter un conteneur
docker rm NOM_CONTENEUR         # Supprimer un conteneur
docker logs NOM_CONTENEUR       # Voir les logs
```
Gestion des volumes Docker
```bash
docker volume ls                    # Lister les volumes
docker volume create NOM_VOLUME     # Créer un volume
docker volume inspect NOM_VOLUME    # Afficher un volume
docker volume rm NOM_VOLUME         # Supprimer un volume
```
Docker Compose
```bash
nano compose.yaml           # Créer un fichier Compose
docker compose up -d        # Démarrer une application
docker compose down         # Arrêter une application
docker compose ps           # Voir les services
docker compose logs         # Afficher les logs
docker compose pull         # Mettre à jour les images
docker compose restart      # Redémarrer les services
```
Maintenance Docker
```bash
docker info                 # Informations Docker
docker system df            # Utilisation disque
docker system prune         # Nettoyage Docker
```
Organisation des services Homelab
Service	Dossier
Pi-hole	`~/homelab/docker/pihole`
Portainer	`~/homelab/docker/portainer`
Homepage	`~/homelab/docker/homepage`
Grafana	`~/homelab/docker/monitoring/grafana`
Prometheus	`~/homelab/docker/monitoring/prometheus`
Node Exporter	`~/homelab/docker/monitoring/node-exporter`
Uptime Kuma	`~/homelab/docker/uptime-kuma`
VPN (WireGuard)	`~/homelab/docker/wireguard`
Vérifications finales
```bash
docker --version
docker compose version
docker ps
docker images
docker volume ls
docker network ls
```
État final
Élément	État
Docker installé	✅
Docker Engine fonctionnel	✅
Docker Compose installé	✅
Test hello-world validé	✅
Utilisateur ajouté au groupe Docker	✅
Docker utilisable sans sudo	✅
Réseau Docker `homelab` créé	✅
Structure Homelab créée (`~/homelab/docker`)	✅
Prêt pour Pi-hole	✅
Prêt pour Portainer	✅
Prêt pour Monitoring	✅
Prêt pour VPN	✅
Notes
Les données des applications doivent être stockées dans des volumes Docker ou des dossiers persistants. Objectifs : conserver les configurations ; éviter la perte de données ; permettre la recréation des conteneurs ; faciliter la maintenance du Homelab.
---
Administration Docker avec Portainer
Objectif
Installation et configuration de Portainer pour l'administration graphique du Homelab Docker.
Objectifs :
Créer le dossier Portainer
Rédiger le fichier Docker Compose
Ouvrir le port nécessaire sur le pare-feu
Démarrer et tester Portainer
Créer le compte administrateur
Préparer le dossier Portainer
📍 Où : terminal SSH sur le Raspberry Pi
```bash
cd ~/homelab/docker
mkdir portainer
cd portainer
```
Créer le fichier Docker Compose
```bash
nano compose.yaml
```
Contenu à ajouter :
```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - homelab

volumes:
  portainer_data:

networks:
  homelab:
    external: true
```
Ce fichier suppose que le réseau `homelab` a déjà été créé à l'étape 4.11 (`docker network create homelab`) — sinon le démarrage échouera.
Explication du fichier
Image `image: portainer/portainer-ce:latest` → télécharge l'image officielle Portainer Community Edition.
Nom du conteneur `container_name: portainer` → nom fixe pour l'administration.
Redémarrage automatique `restart: unless-stopped` → redémarre après un reboot, redémarre après un crash, sauf si arrêté volontairement.
Port Web `ports: - "9443:9443"` → port HTTPS sécurisé de Portainer. Accès : `https://192.168.1.50:9443` (IP fictive d'exemple, à remplacer par la tienne en local uniquement).
Docker Socket `/var/run/docker.sock:/var/run/docker.sock` → c'est ce qui permet à Portainer de contrôler Docker. Sans cela : pas de création de conteneur, pas de gestion Docker.
Volume `portainer_data:/data` → conserve utilisateurs, paramètres et configurations, même après suppression du conteneur.
Problème rencontré : port manquant dans le fichier Compose
Lors de la première rédaction du fichier `compose.yaml`, la ligne du port n'avait pas été ajoutée (`ports: - "9443:9443"`). Conséquence : Portainer démarrait mais restait inaccessible depuis le navigateur.
Correction : ajouter la ligne `ports` ci-dessus dans le fichier, puis recréer le conteneur pour appliquer le changement :
```bash
docker compose up -d --force-recreate
```
Ouvrir le port sur le pare-feu du Raspberry
Le port `9443` doit aussi être ouvert au niveau du pare-feu du Raspberry (UFW), sinon la page ne s'affiche pas même si le conteneur tourne.
```bash
sudo ufw status                    # Vérifier l'état du pare-feu
sudo ufw allow 9443/tcp            # Ouvrir le port 9443 en TCP
sudo ufw reload                    # Recharger le pare-feu
sudo ufw status numbered           # Vérifier que la règle est bien active
```
Démarrer Portainer
```bash
cd ~/homelab/docker/portainer
docker compose up -d
docker ps
```
Résultat attendu : `portainer   Up`
Vérifier les logs
```bash
docker logs portainer
```
Résultat attendu : `Starting Portainer`
Tester l'accès web
Vérifier que le port répond localement sur le Raspberry :
```bash
curl -k https://localhost:9443
```
Depuis le navigateur d'un autre appareil du réseau :
```
https://192.168.1.50:9443
```
Le navigateur affichera probablement `Your connection is not private` — c'est normal, Portainer utilise un certificat auto-signé. Cliquer sur « Continuer » / « Avancé » pour accéder à l'interface.
Création du compte administrateur
⚠️ Portainer laisse exactement 5 minutes après le démarrage du conteneur pour créer le compte admin. Passé ce délai, l'instance se verrouille et affiche une erreur — il faut alors redémarrer le conteneur (`docker restart portainer`) pour obtenir une nouvelle fenêtre de 5 minutes.
Utilisateur : `admin`
Mot de passe : minimum 12 caractères, majuscules, minuscules, chiffres, caractères spéciaux.
Ce compte admin est propre à l'interface web Portainer — il n'a aucun rapport avec ton utilisateur système Linux (`TON_UTILISATEUR`, celui utilisé pour te connecter en SSH). Ce sont deux comptes distincts, sur deux systèmes différents.
Astuce pour éviter le blocage des 5 minutes : il est possible de pré-configurer le mot de passe admin dès le démarrage du conteneur, via un hash bcrypt, pour ne jamais dépendre de ce délai :
```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'TonMotDePasse' | cut -d ":" -f 2
```
Puis ajouter dans le compose (les `$` doivent être doublés `$$` pour échapper la syntaxe Docker Compose) :
```yaml
    command: --admin-password=$$2y$$05$$<hash-généré>
```
⚠️ Ce flag ne s'applique qu'au tout premier démarrage (quand Portainer n'a pas encore de compte admin en base). Aux redémarrages suivants, c'est le mot de passe déjà stocké qui prévaut. Ne jamais committer ce hash sur un dépôt public.
Récupérer le Setup Token (si demandé)
Certaines versions de Portainer demandent un Setup Token lors de l'initialisation. Récupérer le token dans les logs sur le Raspberry :
```bash
docker logs portainer 2>&1 | grep setup_token
```
Changer le mot de passe admin après coup
Contrairement à Pi-hole, ça ne se fait pas en ligne de commande mais depuis l'interface web :
Se connecter sur `https://192.168.1.50:9443`
En haut à droite, cliquer sur le nom d'utilisateur / icône de profil
Aller dans « My account »
Saisir le mot de passe actuel puis le nouveau
Si le mot de passe est perdu (pas juste à changer volontairement), il faut repasser par une réinitialisation complète (voir 5.14).
Créer une stack dans Portainer
Une « stack » dans Portainer correspond à une application définie par un fichier `compose.yaml` (un ou plusieurs conteneurs liés). Il existe deux façons de gérer les services de ce Homelab, à ne pas mélanger :
Méthode A — en ligne de commande SSH (méthode retenue pour ce Homelab)
```bash
cd ~/homelab/docker/<service>
docker compose up -d
```
Avantage : le fichier `compose.yaml` reste la seule source de vérité, versionné sur GitHub. C'est la méthode utilisée pour tous les services de ce document (Pi-hole, Homepage, Portainer lui-même, etc.).
⚠️ Un service lancé ainsi affichera dans Portainer le message "This stack was created outside of Portainer. Control over this stack is limited." — ce n'est pas une erreur, juste une information : Portainer peut voir le conteneur (logs, stats, start/stop/restart) mais ne peut pas éditer son compose ni le redéployer en un clic depuis l'interface, puisqu'il n'a pas créé la stack lui-même.
Méthode B — depuis l'interface Portainer (alternative, non utilisée par défaut ici)
Aller dans Stacks → Add stack
Donner un nom à la stack
Coller le contenu du `compose.yaml` du service dans l'éditeur (« Web editor »)
Cliquer sur Deploy the stack
Avantage de cette méthode : édition et redeploy possibles directement depuis l'interface Portainer.
Inconvénient : si elle est utilisée en parallèle de la méthode A (SSH + Git), les deux versions du fichier peuvent diverger et créer de la confusion sur laquelle fait foi. Pour ce Homelab, on garde la méthode A comme référence unique, Portainer servant surtout à la supervision.
Réinitialiser Portainer (mot de passe perdu / instance à repartir de zéro)
```bash
docker stop portainer
docker rm portainer
docker volume rm portainer_data
cd ~/homelab/docker/portainer
docker compose up -d
```
Reconnecte-toi ensuite sur `https://192.168.1.50:9443` dans les 5 minutes pour recréer un compte admin (voir 5.10).
Vérifications finales
```bash
docker ps                          # Conteneur actif
docker logs portainer              # Logs sans erreur
sudo ufw status numbered           # Règle de pare-feu active
curl -k https://localhost:9443     # Test d'accès HTTPS
```
État final
Élément	État
Dossier Portainer créé (`~/homelab/docker/portainer`)	✅
Fichier `compose.yaml` rédigé	✅
Réseau `homelab` disponible	✅
Port 9443 ajouté au `compose.yaml`	✅
Port 9443 ouvert sur le pare-feu (UFW)	✅
Conteneur Portainer démarré	✅
Accès HTTPS testé	✅
Compte administrateur créé	✅
Setup Token récupéré (si demandé)	✅
---
Pi-hole (DNS + blocage publicitaire)
Objectif
Installer Pi-hole comme serveur DNS pour bloquer les publicités et trackers à l'échelle du réseau local.
Préparer le dossier
📍 Où : terminal SSH sur le Raspberry Pi
```bash
cd ~/homelab/docker
mkdir pihole
cd pihole
nano compose.yaml
```
Fichier Docker Compose
```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    restart: unless-stopped
    environment:
      TZ: "Europe/Paris"
      WEBPASSWORD: "ChangerMotDePasse"
      DNSMASQ_USER: "root"
    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    dns:
      - 127.0.0.1
      - 1.1.1.1
    cap_add:
      - NET_ADMIN
    networks:
      - homelab

networks:
  homelab:
    external: true
```
Remplace `WEBPASSWORD` par un vrai mot de passe fort avant de démarrer — ne laisse jamais la valeur d'exemple, et ne mets jamais le vrai mot de passe dans ce fichier une fois versionné sur GitHub.
Explication des points importants
`TZ: Europe/Paris` → sans ça, les horaires dans les logs et les statistiques seraient en UTC, décalés de ton heure locale.
`53:53/tcp` et `53:53/udp` → le DNS utilise les deux protocoles ; il faut ouvrir les deux, sinon certaines requêtes échoueront de façon aléatoire.
`80:80/tcp` → interface web d'administration. Si le port 80 est déjà utilisé par un autre service sur le Raspberry, remplace par exemple par `8080:80` et adapte l'URL d'accès en conséquence.
`DNSMASQ_USER: "root"` → ajusté en pratique pour un fonctionnement correct du service DNS interne.
`dns: - 127.0.0.1 / - 1.1.1.1` → DNS utilisés par le conteneur lui-même pour ses propres résolutions.
`cap_add: NET_ADMIN` → capacité système nécessaire à la gestion réseau avancée par Pi-hole (nécessaire notamment pour le bon fonctionnement du DHCP/DNS selon la configuration).
`networks: - homelab` → place Pi-hole sur le même réseau Docker partagé que les autres services.
Les deux volumes (`etc-pihole`, `etc-dnsmasq.d`) conservent la configuration (listes de blocage, réglages DNS) même si le conteneur est recréé.
Démarrer et vérifier
📍 Où : terminal SSH, dans `~/homelab/docker/pihole`
```bash
docker compose up -d
docker ps
docker logs pihole
```
Tu dois voir dans les logs une ligne confirmant que le blocage est actif.
Ouvrir les ports sur le pare-feu (UFW)
📍 Où : terminal SSH sur le Raspberry Pi
```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 80/tcp
sudo ufw status
```
Accéder à l'interface web
📍 Où : navigateur, PC ou téléphone sur le réseau local
```
http://192.168.1.50/admin
```
Pi-hole ne demande qu'un mot de passe pour se connecter (pas de nom d'utilisateur séparé) — celui défini via `WEBPASSWORD` ou changé ensuite avec `pihole setpassword` (voir 6.13).
Configurer le DNS amont
📍 Où : navigateur, interface Pi-hole → Settings → DNS
Pi-hole doit lui-même interroger un DNS externe pour les domaines non bloqués. Choisis-en un :
Cloudflare : `1.1.1.1` et `1.0.0.1`
Google : `8.8.8.8` et `8.8.4.4`
Cloudflare est un bon choix par défaut pour un usage familial (rapide, respecte davantage la vie privée que Google).
Ajouter des listes de blocage supplémentaires
📍 Où : navigateur, interface Pi-hole → Group Management → Adlists
Ajouter par exemple :
```
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```
Puis appliquer : Tools → Update Gravity.
Tester que Pi-hole fonctionne réellement
📍 Où : un PC ou téléphone du réseau local
Vérifier le DNS utilisé (Windows) :
```bash
ipconfig /all
```
Chercher la ligne `Serveurs DNS`.
Tester une résolution :
```bash
nslookup google.com
```
Si la ligne `Server:` affiche l'IP de ton Raspberry, c'est que Pi-hole répond bien aux requêtes.
Faire utiliser Pi-hole par tout le réseau
📍 Où : interface d'administration de ta box Internet, section DHCP
Change le DNS primaire distribué par le DHCP : remplace le DNS de ton opérateur par l'IP de ton Raspberry. Tous les appareils qui se reconnectent au Wi-Fi/réseau (téléphone, PC, tablette, TV) utiliseront alors Pi-hole automatiquement.
⚠️ Piège classique à éviter : ne mets pas un DNS secondaire différent de Pi-hole (ex. `8.8.8.8`) dans la box. Certains appareils basculent automatiquement sur le DNS secondaire en cas de lenteur, ce qui contourne complètement le blocage. Pour un blocage total, ne renseigne que l'IP du Raspberry, sans secondaire.
Créer la stack Pi-hole dans Portainer (alternative à la ligne de commande)
Comme pour tout service géré via SSH + `compose.yaml` (voir Partie 5.13), Pi-hole apparaîtra dans Portainer avec le message "This stack was created outside of Portainer" si tu l'as lancé en ligne de commande — c'est normal et sans conséquence pour son fonctionnement.
Si tu préfères malgré tout la créer/gérer depuis Portainer :
Stacks → Add stack
Nommer la stack `pihole`
Coller le contenu de `compose.yaml` (section 6.3)
Deploy the stack
⚠️ Ne fais ceci que si tu abandonnes la gestion en ligne de commande pour ce service, pour éviter que les deux méthodes divergent.
Changer le mot de passe web
Modifier `WEBPASSWORD` dans le fichier `compose.yaml` ne change rien sur une instance déjà initialisée — cette variable n'est prise en compte qu'à la toute première création du conteneur. Pour changer le mot de passe une fois Pi-hole déjà en place :
```bash
docker exec -it pihole pihole setpassword
```
(saisie interactive, invisible à l'écran)
Ou directement :
```bash
docker exec -it pihole pihole setpassword 'TonNouveauMotDePasse'
```
(entouré de guillemets simples, surtout si le mot de passe contient des caractères spéciaux)
Commandes utiles
📍 Où : terminal SSH sur le Raspberry Pi
```bash
docker ps | grep pihole
docker logs -f pihole
docker restart pihole
```
Mise à jour :
```bash
cd ~/homelab/docker/pihole
docker compose pull
docker compose up -d
```
État final
Élément	État
Dossier Pi-hole créé (`~/homelab/docker/pihole`)	✅
Fichier `compose.yaml` rédigé	✅
Réseau `homelab` rejoint	✅
Ports 53 (tcp/udp) et 80 ajoutés au `compose.yaml`	✅
Ports ouverts sur le pare-feu (UFW)	✅
Conteneur Pi-hole démarré	✅
Interface web accessible	✅
DNS amont configuré (Cloudflare/Google)	✅
Listes de blocage supplémentaires ajoutées	✅
Test `nslookup` validé	✅
DHCP de la box pointé vers Pi-hole	✅
Mot de passe web changé après initialisation	✅
---
Homepage (tableau de bord centralisé)
Objectif
Une seule page qui liste tous tes services au lieu de devoir retenir chaque URL et chaque port.
Préparer le dossier
📍 Où : terminal SSH sur le Raspberry Pi
```bash
cd ~/homelab/docker
mkdir homepage
cd homepage
mkdir config
```
Fichier Docker Compose
```bash
nano compose.yaml
```
Contenu :
```yaml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      HOMEPAGE_ALLOWED_HOSTS: "*"
    networks:
      - homelab

networks:
  homelab:
    external: true
```
⚠️ Conflit de port à anticiper : Grafana (Partie 8) utilise aussi le port `3000` par défaut. Comme Homepage prend `3000` en premier ici, il faudra changer le port de Grafana (par exemple `3001:3000`) — sinon le deuxième des deux services à démarrer refusera de se lancer. Ce changement est noté dans la Partie 8.
`HOMEPAGE_ALLOWED_HOSTS: "*"` autorise l'accès depuis n'importe quelle IP/nom d'hôte ; c'est adapté pour un usage LAN, à restreindre si tu exposais un jour ce service publiquement.
Démarrer Homepage
📍 Où : terminal SSH, dans `~/homelab/docker/homepage`
```bash
docker compose up -d
docker ps
```
Accéder au dashboard
📍 Où : navigateur, réseau local
```
http://192.168.1.50:3000
```
La page est vide au premier lancement : c'est normal, tout se configure par fichiers YAML (étapes suivantes).
Configuration générale
📍 Où : terminal SSH, fichier `config/settings.yaml`
```bash
nano config/settings.yaml
```
Contenu :
```yaml
title: Homelab Raspberry Pi
theme: dark
color: slate
headerStyle: clean
language: fr
```
⚠️ Attention à ne rien laisser traîner après la dernière ligne (pas de `---` ni de caractères résiduels issus d'un copier-coller) : une valeur `fr---` par exemple provoque une erreur `Invalid language tag` au chargement de la page. En cas de doute, vérifier le fichier avec `cat -A config/settings.yaml` pour repérer les caractères invisibles.
Déclarer les services
📍 Où : terminal SSH, fichier `config/services.yaml`
```bash
nano config/services.yaml
```
Contenu (à compléter au fur et à mesure que tu installes des services) :
```yaml
- Infrastructure:
    - Pi-hole:
        icon: pi-hole.png
        href: http://192.168.1.50/admin
        description: DNS + bloqueur publicitaire
    - Portainer:
        icon: portainer.png
        href: https://192.168.1.50:9443
        description: Gestion Docker

- Monitoring:
    - Grafana:
        icon: grafana.png
        href: http://192.168.1.50:3001
        description: Tableaux de bord
    - Uptime Kuma:
        icon: uptime-kuma.png
        href: http://192.168.1.50:3002
        description: Supervision
```
(Les ports Grafana/Uptime Kuma ci-dessus sont ceux corrigés — voir les notes de conflit de ports dans les Parties 8 et 9.)
L'indentation compte : un tiret représente un élément de liste (catégorie ou service), et `icon`/`href`/`description` doivent être indentés sous le nom du service auquel ils appartiennent. `icon:` fait référence à une icône de la bibliothèque intégrée de Homepage (dashboard-icons) — rien à télécharger, juste le bon nom de fichier.
Créer la stack Homepage dans Portainer (alternative à la ligne de commande)
Comme pour Pi-hole (voir 6.12) et selon le principe posé en 5.13 : si Homepage est lancé en ligne de commande via `docker compose up -d`, Portainer l'affichera avec le message "This stack was created outside of Portainer. Control over this stack is limited." — sans conséquence sur son fonctionnement, juste une limite d'édition depuis l'interface.
Pour le créer/gérer depuis Portainer à la place :
Stacks → Add stack
Nommer la stack `homepage`
Coller le contenu de `compose.yaml` (section 7.3)
Deploy the stack
Tester que Homepage fonctionne correctement
```bash
curl -I http://localhost:3000
```
Résultat attendu : `HTTP/1.1 200 OK`. Si la réponse est correcte en local mais que la page ne s'ouvre pas depuis un autre appareil du réseau, vérifier :
Le pare-feu (`sudo ufw status` / `sudo ufw allow 3000/tcp`)
Que l'appareil qui tente la connexion est bien sur le même réseau local que le Raspberry
L'IP actuelle du Raspberry (`hostname -I`), au cas où elle aurait changé
État final
Élément	État
Dossier Homepage créé (`~/homelab/docker/homepage`)	✅
Fichier `compose.yaml` rédigé	✅
Réseau `homelab` rejoint	✅
Port 3000 ouvert sur le pare-feu (UFW)	✅
Conteneur Homepage démarré	✅
`settings.yaml` configuré	✅
`services.yaml` configuré (Pi-hole, Portainer, Grafana, Uptime Kuma)	✅
Accès web testé et fonctionnel	✅
