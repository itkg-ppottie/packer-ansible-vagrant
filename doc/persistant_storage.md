# Persitant Storage

## GlusterFS
### présentation

GlusterFS est un logivciel libre de système de fichiers distribué en parrallèle, capable de monter jusqu'a plusieurs pétaoctets. 

### Architecture
GlusterFS repose sur un modèle client-serveur. Les Serveurs sont typiquement déployés comme des «briques de stockage», chaque serveur exécutant un daemon glusterfsd qui exporte un système de fichier local comme un «volume». Le processus client glusterfs, qui se connecte aux serveurs avec un protocole spécifique (implémenté au-dessus de TCP/IP, InfiniBand ou SDP), regroupe les volumes distants en un unique volume. Le volume résultant est alors monté par l'hôte client par un mécanisme FUSE. Les applications traitant des nombreuses entrées/sorties peuvent aussi utiliser la bibliothèque client libglusterfs pour se connecter directement à des serveurs et exécuter les traducteurs de façon interne sans avoir à passer par le système de fichier et le sur-débit induit par FUSE.

La plupart des fonctionnalités de GlusterFS sont implémentées comme traducteurs, incluant :

Duplication et Réplication par fichier
Partage de charge par fichier
Gestion des pannes
Ordonnancement et Cache disque
Quotas
Le serveur GlusterFS server est conçu très simplement: il exporte un système de fichier existant comme tel, laissant aux traducteurs côté client la tâche de structurer l'espace. Les clients eux-mêmes sont sans état, ne communiquent pas entre eux, et sont censés disposer de configurations de traducteurs cohérents entre eux. Cela peut poser des problèmes, mais permet à GlusterFS de monter jusqu'à plusieurs peta-octets sur du matériel habituel en évitant les goulots d'étranglements qui affectent normalement les systèmes de fichiers distribués plus stricts.

#### Deployement du cluster

For GlusterFS to connect between servers, TCP ports 24007, 24008, and 24009/49152+ (that port, plus an additional incremented port for each additional server in the cluster; the latter if GlusterFS is version 3.4+), and TCP/UDP port 111 must be open. You can open these using whatever firewall you wish (this can easily be configured using the geerlingguy.firewall role).