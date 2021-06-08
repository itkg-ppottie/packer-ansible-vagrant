# Persitant Storage avec GlusterFS

## GlusterFS
### présentation

GlusterFS est un logivciel libre de système de fichiers distribué en parrallèle, capable de monter jusqu'a plusieurs pétaoctets. 

### Architecture

[https://docs.gluster.org/en/latest/Quick-Start-Guide/Architecture/](https://docs.gluster.org/en/latest/Quick-Start-Guide/Architecture/)

GlusterFS repose sur un modèle client-serveur. Les Serveurs sont typiquement déployés comme des «briques de stockage», chaque serveur exécutant un daemon glusterfsd qui exporte un système de fichier local comme un «volume». Le processus client glusterfs, qui se connecte aux serveurs avec un protocole spécifique (implémenté au-dessus de TCP/IP, InfiniBand ou SDP), regroupe les volumes distants en un unique volume. Le volume résultant est alors monté par l'hôte client par un mécanisme FUSE. Les applications traitant des nombreuses entrées/sorties peuvent aussi utiliser la bibliothèque client libglusterfs pour se connecter directement à des serveurs et exécuter les traducteurs de façon interne sans avoir à passer par le système de fichier et le sur-débit induit par FUSE.

La plupart des fonctionnalités de GlusterFS sont implémentées comme traducteurs, incluant :

* Duplication et Réplication par fichier
* Partage de charge par fichier
* Gestion des pannes
* Ordonnancement et Cache disque
* Quotas
Le serveur GlusterFS server est conçu très simplement: il exporte un système de fichier existant comme tel, laissant aux traducteurs côté client la tâche de structurer l'espace. Les clients eux-mêmes sont sans état, ne communiquent pas entre eux, et sont censés disposer de configurations de traducteurs cohérents entre eux. Cela peut poser des problèmes, mais permet à GlusterFS de monter jusqu'à plusieurs peta-octets sur du matériel habituel en évitant les goulots d'étranglements qui affectent normalement les systèmes de fichiers distribués plus stricts.


Pour que  GlusterFS se connecte entre les serveurs, il faut autoriser les les flux entre les ports suivant :
* 24007 (TCP),
* 24008 (TCP),
* 24009/49152+ (TCP)
* 111 (TCP/UDP)
(Pour la version de GlusterFS 3.4+ : le port 49152+ est un port addictionnel incrémenté pour chaque serveur ajouté au cluster )
ainsi que le port TCP/UDP

### Configuration du cluster

GlusterFS est à deployer sur chaque machine hote du cluster

https://docs.gluster.org/en/latest/Install-Guide/Install/

Par défaut c'est une systeme de repartition des fichiers (rebalance) qui est appliqué, plus rapide que la fonctionnaltié de replication mais il n'offre pas les deux  fonctionnalités les plus recherchées de Gluster:
* plusieurs copies des données,
* le basculement automatique en cas de problème.

Il est recomandé de passer en cluster 3 noeuds minimum pour beneficier de la fonctionnalité de replication.

Dans le contexte du projet de replication d'un environnement sous VM il est deployé via Ansible sur chaque noeud du swarm.

Par le suite, au fure et amesure des optimisations nécessaire, le cluster pourra etre deplacer sur:

* des MV : 
[https://docs.gluster.org/en/latest/Install-Guide/Setup-virt/](https://docs.gluster.org/en/latest/Install-Guide/Setup-virt/)

* des machines physiques dédiées : 
[https://docs.gluster.org/en/latest/Install-Guide/Setup-Bare-metal/](https://docs.gluster.org/en/latest/Install-Guide/Setup-Bare-metal/)


Dans l'état actuel des ressources le cluster sera installé sur les machine hote des noeuds composant le cluster SWARM.

Le systeme de fichier préconisé est XFS mais adns l'état acutel des ressources le ext4 sera bien suffisant;

## deploiement dans le projet de VM


## Installation manuelle dans l'environnement de preproduction 

https://docs.gluster.org/en/latest/Install-Guide/Install/

Ces actions sont à effectuer sur chaque noeud du swarm

ajouter à apt la clef GPG :
```shell
$ wget -O - https://download.gluster.org/pub/gluster/glusterfs/7/rsa.pub | apt-key add -
```

ajouter le repo apt à sa liste de sources apt
```shell
$ DEBID=$(grep 'VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
$ DEBVER=$(grep 'VERSION=' /etc/os-release | grep -Eo '[a-z]+')
$ DEBARCH=$(dpkg --print-architecture)
$ echo deb https://download.gluster.org/pub/gluster/glusterfs/LATEST/Debian/${DEBID}/${DEBARCH}/apt ${DEBVER} main > /etc/apt/sources.list.d/gluster.list
```

Mettre a jour son systeme de package
```shell
$ sudo apt-get update
```
Installer le serveur GlusterFS:
```shell
$ sudo apt-get install glusterfs-server
```

## configuration du cluster

### Ajouter une noeud
enregistrer chaque noeud du cluster sur chaque noeud:

````
sudo gluster peer probe  node01 node02 node03
````

`nodeXX ` correspondant a un nom dns ou une adresse ip des autres noeuds du cluster GlusterFS


consulter l'état du cluster 

```shell
$ gluster peer status
```

### Ajouter un volume Gluster

Créer l'espace de stockage sur chaque noeud, s'il n'existe pas

```
$ mkdir -p /var/gluster/brick
```

Sur n'importe quel noeud, créer un volume Gluster
```shell
gluster volume create gv0 replica 2 node01:/var/gluster/brick node02:/var/gluster/brick
```

Vérifiez que la création s'est correctement déroulée:

```shell
$ gluster volume info
And you should see results similar to the following:

    Volume Name: gv0
    Type: Replicate
    Volume ID: 8bc3e96b-a1b6-457d-8f7a-a91d1d4dc019
    Status: Created
    Number of Bricks: 1 x 2 = 2
    Transport-type: tcp
    Bricks:
    Brick1: node01:/var/gluster/brick
    Brick2: node02:/var/gluster/brick
```
Démarrer le partage du nouveau volume:
```shell
$  gluster volume start gv0
```


## Installation du client Gluster

Le client Gluster est installer sur chaque noeud du cluster SWARM
afin que chaque noeud ait l'acces au repertoires partagés de gluster.

### Préconisation
Avant d'installe le client natif Gluster , il est impératif de vérifier que le module kernel FUSE est bien chargé sur chaque machine cliente.

Charger le module kernel FUSE (LKM) dans le kernel Linux:
```shell
$ modprobe fuse
```

Verifier que le module est bien chargé
```shell
$ dmesg | grep -i fuse fuse init (API version 7.13)
```

###  Installation du package debian

https://docs.gluster.org/en/latest/Install-Guide/Install/

Ces actions sont à effectuer sur chaque noeud du swarm

ajouter à apt la clef GPG :
```shell
$ wget -O - https://download.gluster.org/pub/gluster/glusterfs/7/rsa.pub | apt-key add -
```

ajouter le repo apt à sa liste de sources apt
```shell
$ DEBID=$(grep 'VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
$ DEBVER=$(grep 'VERSION=' /etc/os-release | grep -Eo '[a-z]+')
$ DEBARCH=$(dpkg --print-architecture)
$ echo deb https://download.gluster.org/pub/gluster/glusterfs/LATEST/Debian/${DEBID}/${DEBARCH}/apt ${DEBVER} main > /etc/apt/sources.list.d/gluster.list
```

Mettre a jour son systeme de package
```shell
$ sudo apt-get update
```
installer le package client

```shell
$ apt-get install  glusterfs-client 
```

## Montage des volumes partagés

Commandes à effectuer sur chaque noeuds du cluster 

```shell
$ mount -t glusterfs HOSTNAME-OR-IPADDRESS:/VOLNAME MOUNTDIR
```

exemple pour le node01:
```shell
$ mount -t glusterfs node01:/gv0 /mnt/glusterfs
```
### Montage automatique

Ajouetr dans le fichier /etc/fstab

```
HOSTNAME-OR-IPADDRESS:/VOLNAME MOUNTDIR glusterfs defaults,_netdev 0 0
```

exemple pour le node01:
```
node01/gv0 /mnt/glusterfs glusterfs defaults,_netdev 0 0
```

### Tester Le partage

aller sur node01 et créer un fichier dans le repertoire partagé

```shell
$ touch /mnt/glusterfs/toto
```

Aller sur  node02 et constater la présence du fichier crée sur node01
```
$ ls /mnt/glusterfs/
```

Adapter les droits d'ecriture sur les repertoires si besoin

## ​ Fichiers de logs 

Les fichiers de logs à surveiller poru cette configuration sont :
    * Glusterd:  `/var/log/glusterfs/glusterd.log`. Un fichier  glusterd.log  par serveur. 
    * Gluster cli command: `/var/log/glusterfs/cli.log`. Commandes gluster executées sur un nœud 
    * Bricks:  `/var/log/glusterfs/bricks/<path extraction of brick path>`.log . Un fichier de log par brick et par nœud.