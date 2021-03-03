
# Création d’une architecture virtuelle des environnements 



## Objectifs :
Obtenir un environnement de développement et de tests des architectures actuelles pour l’intégration de nouvelles solutions menant à la scalabilité ou l’auto-scalabilité des services, le monitoring, etc sans impacter les architectures actuelles.

## Demo

<!-- blank line -->
<figure class="video_container">
  <iframe src="https://www.youtube.com/watch?v=8RX9aBII_3s" frameborder="0" allowfullscreen="true"> </iframe>
</figure>
<!-- blank line -->


## Comment s’y prendre ?

Il nous faut pouvoir prévoir les interventions d’installation, configuration et de tests pour modifier ces environnements en minimisant l’impact et les incidents.
Pour cela, il nous faut :
* Reproduire l’architecture prod et preprod dans l’état des solutions actuellement sous docker et destinées à être basculées sous Docker Swarm.

 * Définir un protocole d’intervention pour chaque étape pour la bascule des services sous Docker Swarm ou l’ajout d’un outil supplémentaire à l’architecture actuelle

La contrainte la plus importante étant de pouvoir reproduire ces environnements avec un minimum de ressources.



## Vagrant : Provisionning de machines virtuelles

Vagrant est un outil d’HashiCorp (éditeur de Terraform)

Ce programme permet de déployer rapidement des machines virtuelles en exploitant des fichiers de description.
Ainsi en écrivant un fichier VagrantFile, il est possible de déployer en quelques minutes une ou plusieurs machines, en les provisionnant avec des scripts ou des outils tels qu’Ansible.

L’avantage de Vagrant est dans sa possibilité de partage de configuration permettant à une équipe complète de travailler dans les mêmes conditions en local en reproduisant un comportement de production à faible coût.

Un simple fichier texte suffit pour être partagé et il peut donc être versionné avec Gitlab.


## Packer : Packager des machines virtuelles

Packer est également un outil HashiCorp. Son rôle est de packager des machines virtuelles.
Il permet ainsi de créer des AMI AWS, des images Docker, des machines virtuelles Virtualbox et bien d’autres.
https://www.packer.io/docs/builders

Il y a certains avantages à son utilisation :

    • La simplicité de la configuration : un simple fichier JSON ou HCL permet de décrire le build voulu
    • La parallélisation : on peut créer la même image sur plusieurs providers en parallèle, très utile dans une approche multicloud
    • La reproductibilité : Il est simple de pouvoir recréer une image OS from scratch en repartant uniquement des fichiers Packer, ce qui permet de partager uniquement ces fichiers, plutôt que des images volumineuses



## Automatiser la création de machines virtuelles (VM)

Pour permettre la génération rapide de template d’images virtuelles nous allons utiliser Ansible et Packer afin d’avoir un script versionné de nos travaux et permettre l’automatisation de cette étape.
Ceci va nous permettre de définir une ou plusieurs images de base (box)

## Pré-requis


On va donc installer Ansible comme outil de lancement sur la machine hote pour la création des images Virtualbox à partir d’un template Vagrant :

https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

et l’outil Packer pour la création d'une box:

https://www.packer.io/docs/builders

Nous aurons également besoin de vagrant::

https://www.vagrantup.com/docs/installation

## Lancer le build et consttruire l'infrastructure par défaut (preprod)
A la suite de l’exécution du playbook principale build-vm-cluster-swarm.yml 
```shell
$ ansible-playbook build-vm-cluster-swarm.yml
```
Ala fin de l'executon de la tache Packer , nous obtenons au final une box prête à l’emploi :
packer_debian10-10G-vm-swarm-master-01_virtualbox.box

[Automatiser la création d'une VM avec Packer et Ansible](doc/packer_ansible.md)

L'étape suivante sera d'executer vagrant avec  la ou les box créé(es)  pour deployer l'architecture attendue.

[Automatiser la création d'une infrastructuve avec Vagrant et Ansible](doc/vagrant_ansible.md)

Au final de l'execution du playbook principale on obtient ,selon la configuration de l'infrastructure de la preprod (par défaut):

Une VM sous haproxy configuré pour loadbalancing entre les 2 nodes
Une VM avec Docker Swarm configuré en Master
Une VM sous Docker Swarm configuré en worker

