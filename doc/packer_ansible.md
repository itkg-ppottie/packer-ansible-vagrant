
# Création de boxes pour nos futurs machines virtuelles avec Ansible et Packer


On va donc installer Ansible comme outil de lancement sur la machine hote pour la création des images Virtualbox à partir d’un template Vagrant :

https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

et l’outil Packer pour la création d'une box:

https://www.packer.io/docs/builders

Nous aurons également besoin de vagrant::

https://www.vagrantup.com/docs/installation



Script Ansible pour l’exécution des builds de templates d’image Virtualbox (box)

build-vm-cluster-swarm.yml
```yaml
[...]
    - name: create box vm
      shell: bash -c "PATH=$PATH:/opt/packer/ packer build -var 'disk_size={{ item.size }}' -var 'name={{ item.name }}' -on-error=run-cleanup-provisioner packer/debian-10-template.json " > log/debian10-{{ item.name }}.log
      args:
        creates: output-debian10-{{ item.size }}G-{{ item.name }}
      with_items:
        - { name: "vm-swarm-master-01", size: "10"}
      register: packer
[...]
```

La tache `create box vm` execute une ligne de commande shell executant le build de packer en prenant en compte le parametrage passé en tableau à l'attribut `with_items`.

Ainsi, il y a la possibilité d'ajouter à la tache la création de plusieurs box aux caractéristiques specifiques.

```yaml
   with_items:
        - { name: "vm-swarm-master-01", size: "10"}
		- { name: "vm-swarm-worker-01", size: "20"}
		- { name: "vm-bdd-01", size: "150"}
```

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
			"type": "ansible-local",
			"playbook_file": "playbooks/grub.yml"
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

suite à l'installation de docker, il faut modifier grub, un playbook spécifique est utilisé pour cela.

```yaml
		{
			"type": "ansible-local",
			"playbook_file": "playbooks/grub.yml"
		},
```

Pour une utilisation correct de docker dans la VM il faut activer cgroupmemory et swapaccount:

playbooks/grub.yml
```yaml
- name: 'Provision Image'
  hosts: 127.0.0.1
  connection: local
  become: true

  tasks:
    - name: Check if cgroup memory and swapaccount in kernel
      shell: grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub | grep -c "cgroup_enable=memory swapaccount=1"
      register: cgroup_status
      ignore_errors: true
      no_log: true

    - name: Enable cgroup memory and swapaccount
      lineinfile: dest="/etc/default/grub" regexp='GRUB_CMDLINE_LINUX_DEFAULT="(.*)"' line='GRUB_CMDLINE_LINUX_DEFAULT="\1 cgroup_enable=memory swapaccount=1"' backrefs=yes
      when: cgroup_status.stdout == "0"

    - name: update-grub
      shell: update-grub2
      when: cgroup_status.stdout == "0"
```
## Lancer le build
A la suite de l’exécution du playbook principale build-vm-cluster-swarm.yml 
```shell
$ ansible-playbook build-vm-cluster-swarm.yml
```
Ala fin de l'executon de la tache Packer , nous obtenons au final une box prête à l’emploi :
packer_debian10-10G-vm-swarm-master-01_virtualbox.box

L'étape suivante sera d'executer vagrant pour utiliser la(es) box créé(es)  pour deployer l'architecture attendue.

[Automatiser la création d'une infrastructuve avec Vagrant et Ansible](vagrant_ansible.md)