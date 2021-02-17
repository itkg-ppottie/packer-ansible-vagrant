
# Création d’une architecture virtuelle des environnements 



## Objectifs :
Obtenir un environnement de développement et de tests des architectures actuelles pour l’intégration de nouvelles solutions menant à la scalabilité ou l’auto-scalabilité des services, le monitoring, etc sans impacter les architectures actuelles.

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

Pour permettre la génération rapide de template d’images virtuelles nous allons utiliser Ansible afin d’avoir un script versionné de nos tarvaux et permettre l’automatisation de cette étape.
Cei va nous permettre de définir une ou plusieurs images de base (template) avec lesquelles nous allons travailler pour monter l’architecture des environnements

On va donc installer Ansible comme outil de lancement sur la machine hote pour la création des images Virtualbox à partir d’un template Vagrant et l’outil Packer.


https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

Script Ansible pour l’exécution des builds d’images Virtualbox (box)

build-vm-cluster-swarm.yml
```yaml
- name: a play that runs entirely on the ansible host
  hosts: 127.0.0.1
  connection: local

  tasks:
  ### Build instances
    - file: path=log state=directory mode=0755

    - name: create vm
      shell: PATH=$PATH:/opt/packer/ packer build -var 'disk_size={{ item.size }}' -var 'name={{ item.name }}' -on-error=run-cleanup-provisioner packer/debian-10-template.json >> log/debian10-{{ item.name }}.log
      args:
        creates: output-debian10-{{ item.size }}G-{{ item.name }}
      with_items:
        - { name: "vm-swarm-master-01", size: "10"}
```

Le script est pour le moment simple, il pourra par la suite évoluer pour ajouter des étapes supplémentaire ou ajouter des configurations supplémentaire à l’exécution de la tache de création de box pour obtenir des VM ayant des caractéristiques spécifiques.


## Préparation de la box : template Packer 

NB : La tache de création des images utilise le répertoire log pour y stocker les résultats d’exécution de Packer.


La création de la box utilise Packer associé avec le fichier template json packer/debian10-template.json.

```json
{
	"builders": [
	  {
		"boot_command": [
			"<wait> <esc><wait>",

			"install preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/{{user `preseed_path`}} <wait>",
			"debian-installer=fr_FR.UTF-8 <wait>",
			"auto <wait>",
			"locale=fr_FR.UTF-8 keyboard-configuration/layoutcode=fr keyboard-configuration/variantcode=latin9 keymap=skip-config <wait>",
			"kbd-chooser/method=fr <wait>",
			"keyboard-configuration/xkb-keymap=fr <wait>",
			"netcfg/get_hostname={{ user `hostname` }} <wait>",
			"netcfg/get_domain={{ user `domain` }} <wait>",
			"fb=false <wait>",
			"debconf/frontend=noninteractive <wait>",
			"console-setup/ask_detect=false <wait>",
			"console-keymaps-at/keymap=fr <wait>",
			"grub-installer/bootdev=/dev/sda <wait>",
			"<enter><wait>"
		],
		"boot_wait": "10s",
		"disk_size": "{{ user `disk_size`}}000",
		"guest_os_type": "debian_64",
		"headless": true,
		"http_directory": "packer/http",
		"iso_checksum": "sha256:b317d87b0a3d5b568f48a92dcabfc4bc51fe58d9f67ca13b013f1b8329d1306d",
		"iso_url": "https://cdimage.debian.org/mirror/cdimage/archive/10.7.0/amd64/iso-cd/debian-10.7.0-amd64-netinst.iso",
		"name": "debian10-{{ user `disk_size`}}G-{{ user `name`}}",
		"output_directory": "packer/output-debian_10",
		"shutdown_command": "echo '{{user `password`}}'|sudo -S shutdown -h now",
		"ssh_password": "{{user `password`}}",
		"ssh_timeout": "1800s",
		"ssh_username": "{{user `user`}}",
		"type": "virtualbox-iso",
		"vboxmanage": [
			[
				"modifyvm",
				"{{.Name}}",
				"--audio",
				"null"
			  ],
		  [
			"modifyvm",
			"{{.Name}}",
			"--memory",
			"{{ user `memory`}}"
		  ],
		  [
			"modifyvm",
			"{{.Name}}",
			"--cpus",
			"{{ user `cpus`}}"
		  ]
		],
		"vm_name": "Debian-10-Template"
	  }
	],
	"provisioners": [
		{
            "type": "shell",
            "execute_command": "echo '{{user `password`}}' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'",
            "inline": [
				"echo \"deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main\" >> /etc/apt/source.list",
                "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367",
                "/usr/bin/apt-get update",
                "/usr/bin/apt-get -y install ansible"
            ]
        },
		{
			"type": "ansible-local",
			"playbook_file": "playbooks/install_docker.yml"
		},
		{
            "type": "shell",
            "execute_command": "echo '{{user `password`}}' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'",
            "inline": [
                "/usr/bin/apt-get -y remove ansible"
            ]
        }
	],
	"post-processors": [{
		"type": "vagrant",
		"compression_level": "4",
		"keep_input_artifact": true
	}],
	"variables": {
	  "preseed_path": "preseed-debian10.cfg",
	  "cpus": "1",
	  "custom_script": "scripts/empty.sh",
	  "disk_size": "15",
	  "domain": "local",
	  "hostname": "debian10",
	  "memory": "1024",
	  "name": "image",
	  "password": "debian",
	  "user": "debian"
	}
}
```



La box VirtualBox sera constitué à partir d’une **ISO Debian 10** dont sa spécificatione est définit par son URL sur le site de l’éditeur 
```json
	[…]
	"iso_checksum": "sha256:b317d87b0a3d5b568f48a92dcabfc4bc51fe58d9f67ca13b013f1b8329d1306d",
		"iso_url": "https://cdimage.debian.org/mirror/cdimage/archive/10.7.0/amd64/iso-cd/debian-10.7.0-amd64-netinst.iso",
			[…]
```

L’intégralité de l’installation du systeme se fait grâce à Packer est le parametrage *boot_command*

```json
[…]

	"boot_command": [
			"<wait> <esc><wait>",

			"install preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/{{user `preseed_path`}} <wait>",
			"debian-installer=fr_FR.UTF-8 <wait>",
			"auto <wait>",
			"locale=fr_FR.UTF-8 keyboard-configuration/layoutcode=fr keyboard-configuration/variantcode=latin9 keymap=skip-config <wait>",
			"kbd-chooser/method=fr <wait>",
			"keyboard-configuration/xkb-keymap=fr <wait>",
			"netcfg/get_hostname={{ user `hostname` }} <wait>",
			"netcfg/get_domain={{ user `domain` }} <wait>",
			"fb=false <wait>",
			"debconf/frontend=noninteractive <wait>",
			"console-setup/ask_detect=false <wait>",
			"console-keymaps-at/keymap=fr <wait>",
			"grub-installer/bootdev=/dev/sda <wait>",
			"<enter><wait>"
		],
		"boot_wait": "10s",
		"http_directory": "packer/http",
[…]
```

***
Attention : Les exemples trouvés sur internet n’étaient pas fonctionnels.
***

La valeur du parametre *boot_camp est spécifique à la debian 10 et a été modifié pour qu’il s’exécute correctement. C'est ce paramètrage qui dertemine l'automatisation de chaque étape de l'installation de la distribution.


La valeur du paramétrage *boot_wait* est également important selon les ressources disponibles par la machine hôte pour que la VM soit complètement démarrée.

### Preseed Debian : clavier Fr et services minimum

Suite à cette étape, les packages de bases sont installés selon le fichier définies dans « http_directory », le fichier packer/http/preseed-debian10.cfg

```config
# Setting the locales, country
# Supported locales available in /usr/share/i18n/SUPPORTED
d-i debian-installer/language string fr
d-i debian-installer/country string fr
d-i debian-installer/locale string fr_FR
d-i debian-installer/fallbacklocale select fr_FR.UTF-8

### Dates et heure : mode UTC, fuseau horaire Paris, ne pas utiliser ntp
d-i clock-setup/utc boolean true
d-i time/zone string Europe/Paris
d-i clock-setup/ntp boolean false

# Keyboard setting
d-i debian-installer/keymap string fr-latin9
d-i keyboard-configuration/modelcode string pc105
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/layoutcode string fr
d-i keyboard-configuration/xkb-keymap select fr(latin9)
d-i console-keymaps-at/keymap select fr-latin9

# User creation
d-i passwd/user-fullname string debian
d-i passwd/username string debian
d-i passwd/user-password password debian
d-i passwd/user-password-again password debian
d-i user-setup/allow-password-weak boolean true

# Disk and Partitioning setup
d-i partman-auto-lvm/guided_size string max
d-i partman-auto/choose_recipe select atomic
d-i partman-auto/method string lvm
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/confirm_write_new_label boolean true

# Set mirror
apt-mirror-setup apt-setup/use_mirror boolean true
choose-mirror-bin mirror/http/proxy string
d-i mirror/country string manual
d-i mirror/http/directory string /debian
d-i mirror/http/hostname string httpredir.debian.org
d-i mirror/http/proxy string

# Set root password
d-i passwd/root-login boolean false
d-i passwd/root-password-again password debian
d-i passwd/root-password password debian
d-i passwd/user-fullname string debian
d-i passwd/user-uid string 1000
d-i passwd/user-password password debian
d-i passwd/user-password-again password debian
d-i passwd/username string debian

# Package installations
d-i user-setup/encrypt-home boolean false
d-i preseed/late_command string sed -i '/^deb cdrom:/s/^/#/' /target/etc/apt/sources.list
apt-cdrom-setup apt-setup/cdrom/set-first boolean false
apt-mirror-setup apt-setup/use_mirror boolean true
popularity-contest popularity-contest/participate boolean false
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string sudo wget curl open-vm-tools  software-properties-common
d-i pkgsel/install-language-support boolean false
d-i pkgsel/update-policy select none
d-i pkgsel/upgrade select full-upgrade
d-i grub-installer/only_debian boolean true
# Setup passwordless sudo for debian user
d-i preseed/late_command string \
  echo "%debian ALL=(ALL:ALL) NOPASSWD:ALL" > /target/etc/sudoers.d/debian && chmod 0440 /target/etc/sudoers.d/debian
d-i finish-install/reboot_in_progress note
```

Dans ce fichier preeseed :
* le clavier est passé en azerty
*  l’utilisateur *debian* est défini avec un mot de passe simple
*  sudo est activé pour cet utilisateur.

### Personnalisation de la box
Dans le template Packer est également définis le provisionnement de l'image créée. Cette étape va nous permettre de personnaliser la box selon nos besoins.

A cette étape, nous utiliserons Ansible afin de fournir une abstraction de cette personnalisation.
On pourra ainsi faire evoluer le template Packer pour dynamiser le playbook selon les besoins.

```json
[...]
	"provisioners": [
		{
            "type": "shell",
            "execute_command": "echo '{{user `password`}}' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'",
            "inline": [
				"echo \"deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main\" >> /etc/apt/source.list",
                "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367",
                "/usr/bin/apt-get update",
                "/usr/bin/apt-get -y install ansible"
            ]
        },
		{
			"type": "ansible-local",
			"playbook_file": "playbooks/install_docker.yml"
		},
		{
            "type": "shell",
            "execute_command": "echo '{{user `password`}}' | {{ .Vars }} sudo -E -S sh '{{ .Path }}'",
            "inline": [
                "/usr/bin/apt-get -y remove ansible"
            ]
        }
	],
[...]
```

Le playbook ansible s’occupe des installations des services et outils nécessaires à toutes les VM qui utiliseront cette box(installation docker) .
```yml
- name: 'Provision Image'
  hosts: 127.0.0.1
  connection: local
  become: true

  tasks:
    - name: Install aptitude using apt
      apt: name=aptitude state=latest update_cache=yes force_apt_get=yes

    - name: Install required system packages
      apt: name={{ item }} state=present update_cache=yes force_apt_get=yes
      loop: [ 'apt-transport-https', 'ca-certificates', 'curl', 'software-properties-common', 'python3-pip', 'virtualenv', 'python3-setuptools']

    - name: Add Docker GPG apt Key
      apt_key:
        url: https://download.docker.com/linux/debian/gpg
        state: present

    - name: Add Docker Repository
      apt_repository:
        repo: deb https://download.docker.com/linux/debian buster stable
        state: present

    - name: Update apt and install docker-ce
      apt:
        name: "{{item}}"
        state: latest
        force_apt_get: yes
        update_cache: yes
      loop:
        - docker-ce
        - docker-ce-cli
        - containerd.io
    - name: check if docker is ready
      service:
        name: docker
        state: started
        enabled: yes

    - name: Ensure Docker is started and enabled at boot
      # https://docs.ansible.com/ansible/latest/modules/service_module.html
      service:
        name: docker
        state: started
        enabled: true

    - name: Ensure handlers are notified now to avoid firewall conflicts
      # https://docs.ansible.com/ansible/latest/modules/meta_module.html
      meta: flush_handlers

    - name: "Ensure the user {{ ansible_user }} is part of the docker group"
      # https://docs.ansible.com/ansible/latest/modules/user_module.html
      user: 
        name: "{{ ansible_user }}"
        groups: docker
        append: yes
```

A la suite de l’exécution du playbook principale build-vm-cluster-swarm.yml 
```shell
$ ansible-playbook build-vm-cluster-swarm.yml
```

nous obtenons une box prête à l’emploi :
packer_debian10-10G-vm-swarm-master-01_virtualbox.box

