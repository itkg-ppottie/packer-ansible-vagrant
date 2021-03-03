# Créer un cluster swarm avec Vagrant et Ansible et reproduire une infrasctructure

Préconditions:

* Linux, windows or MacOs hote avec au moins 3Go de RAM libre et 30go d'espace sur le disque dur
* Virtualbox : https://www.virtualbox.org/
* Vagrant : https://www.vagrantup.com/
* Ansible : https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

## Définir les environnements

Grace Vagrant et selon un parametrage présent dans le script (Vagrantfile) les machines, spécifications et configuration des services composants un environnement (preprod ou prod) sont définies dans leur repertoire respectifs

```
 / 
 |- preprod
 |   |- conf
 |   |   |- haproxy.cfg
 |   |-vars.vagrantfile.yaml
 |- preprod
 |   |- conf
 |   |   |- haproxy.cfg
 |   |-vars.vagrantfile.yaml
 ```

 ### Apércu de configuration

le fichier `vars.vagrantfile.yaml` est composé des attributs :
* `servers` d'une liste de machines et leurs caractéristiques
  * `name` : le nom de la machine
  * `type` : type d'utilisation dela machine utilisé pour définir le provisionnement à effectuer
      * haproxy
      * swarm
  * `box` : l'image virtualbox de base à utiliser
  * `eth1` : l'adresse ip 
  * `mem` : la quantité de memoire RAM attribuée
  * `cpu` : le nombre de cpu attitré
*  `MANAGERS` : nombre total de manager Swarm (non utilisé pour le moment)
*  `WORKER` : nombre total de worker Swarm  
*  `ANSIBLE_GROUPS`: Groupe Ansible  pour définir les groupes de machines pour le provisionnement par Ansible

#### exemple
```yaml
servers:
  - name: VM-PDDV-HAPROXY
    type: haproxy
    box: ./packer_debian10-10G-vm-swarm-master-01_virtualbox.box
    eth1: 192.168.30.11
    mem: '1024'
    cpu: '1'
  - name: VM-MANAGER1-DCK
    type: swarm
    box: ./packer_debian10-10G-vm-swarm-master-01_virtualbox.box
    eth1: 192.168.30.13
    mem: '1024'
    cpu: '1'
  - name: VM-WORKER1-DCK
    type: swarm
    box: ./packer_debian10-10G-vm-swarm-master-01_virtualbox.box
    eth1: 192.168.30.27
    mem: '1024'
    cpu: '1'
MANAGERS: 1
WORKERS: 1
ANSIBLE_GROUPS:
  managers:
    - VM-MANAGER1-DCK
  workers:
    - VM-WORKER1-DCK
  'all_groups:children':
    - managers
    - workers
 ```

## Apérçu du code


```Vagrantfile
require 'getoptlong'
require 'yaml'

opts = GetoptLong.new(
  [ '--environment', GetoptLong::OPTIONAL_ARGUMENT ]
)

world='preprod'

opts.ordering=(GetoptLong::REQUIRE_ORDER)   ### this line.

opts.each do |opt, arg|
  case opt
    when '--environment'
      world=arg
  end
end
###############################################################################
# Initialization
###############################################################################

# Verify that vagrant.yml exists
root_dir = File.dirname(__FILE__)
vagrantfile = "#{world}/vars.vagrantfile.yaml"
error_msg = "#{vagrantfile} does not exist"
handle_error(error_msg) unless File.exists?(vagrantfile)

# Read box and node configs from vagrant.yml
vagrant_yaml = YAML.load_file(vagrantfile)
error_msg = "#{vagrantfile} exists, but is empty"
handle_error(error_msg) unless vagrant_yaml

servers = vagrant_yaml['servers']
ANSIBLE_GROUPS = vagrant_yaml['ANSIBLE_GROUPS']
WORKERS = vagrant_yaml['WORKERS']
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.forward_agent = true
  config.ssh.username = 'debian'
  config.ssh.password = 'debian'
  config.vm.synced_folder ".","/vagrant", disabled:true
    servers.each do |server|
      config.vm.define server["name"] do |v|
            v.vm.box  = server["box"]
            v.vm.hostname = server["name"]
            v.vm.network :private_network, ip: server["eth1"]
            v.vm.provider "virtualbox" do |vb|
               vb.customize ["modifyvm", :id, "--memory", server["mem"]]
               vb.customize ["modifyvm", :id, "--cpus", server["cpu"]]
            end
        if server["type"] == "haproxy"
            v.vm.provision "ansible" do |ansible|
                ansible.verbose = "vv"
                ansible.extra_vars = {
                  world: world,
                  swarm_bind_port: 2377
                }
                ansible.playbook = "./playbooks/haproxy_playbook.yml"
            end
        end
        if server["type"] == "swarm"
            if server["name"] ==  ANSIBLE_GROUPS["managers"][0]
              vagrant_primary_manager_ip = server["eth1"]
            end
            if server["name"] == ANSIBLE_GROUPS["workers"][WORKERS-1] #playbook when last worker is up
              v.vm.provision "ansible" do |ansible|
                  ansible.verbose = "vv"
                  ansible.limit = "all"
                  ansible.force_remote_user = true
                  ansible_ssh_user= "root"
                  ansible.groups = ANSIBLE_GROUPS
                  ansible.extra_vars = {
                    vagrant_primary_manager_ip: servers[1]['eth1'],
                    manager_primary: ANSIBLE_GROUPS["managers"][0],
                    swarm_bind_port: 2377
                  }
                  ansible.playbook = "./playbooks/swarm.yml"
              end
            end
        end
      end
    end
end
 ```

Le script Vagrant (Vagrantfile) prend en compte le parametre `--environment` permettant de définir l'environnement à construire :
* `preprod` (par défaut)
* `prod`
```Vagrantfile
    [...]
    opts = GetoptLong.new(
    [ '--environment', GetoptLong::OPTIONAL_ARGUMENT ]
    )

    world='preprod'

    opts.ordering=(GetoptLong::REQUIRE_ORDER)   ### this line.

    opts.each do |opt, arg|
    case opt
        when '--environment'
        world=arg
    end
    end
    [...]
 ```

La variable `world` est prend ainsi la valeur passé à l'execution de vagrant et utilisé dans le traitement du chargement des fichiers de configuration

```Vagrantfile
[...]
###############################################################################
# Initialization
###############################################################################

# Verify that vagrant.yml exists
root_dir = File.dirname(__FILE__)
vagrantfile = "#{world}/vars.vagrantfile.yaml"
error_msg = "#{vagrantfile} does not exist"
handle_error(error_msg) unless File.exists?(vagrantfile)

# Read box and node configs from vagrant.yml
vagrant_yaml = YAML.load_file(vagrantfile)
error_msg = "#{vagrantfile} exists, but is empty"
handle_error(error_msg) unless vagrant_yaml

servers = vagrant_yaml['servers']
ANSIBLE_GROUPS = vagrant_yaml['ANSIBLE_GROUPS']
WORKERS = vagrant_yaml['WORKERS']
[...]
 ```

Chaque serveur défini dans le fichier de configuration est créé selon les caractéristiques données sous virtualbox selon le nom de chaque machine.

```Vagrantfile
[...]
    servers.each do |server|
      config.vm.define server["name"] do |v|
            v.vm.box  = server["box"]
            v.vm.hostname = server["name"]
            v.vm.network :private_network, ip: server["eth1"]
            v.vm.provider "virtualbox" do |vb|
               vb.customize ["modifyvm", :id, "--memory", server["mem"]]
               vb.customize ["modifyvm", :id, "--cpus", server["cpu"]]
            end
[...]
 ```

 ## Provision des VM avec Ansible
L'attribut `type`  dans la configuration du serveur du fichier de configuration permet de définir le provisionnement à effectuer via Ansible.

 ### HAPROXY

L'étape de provisionnement de Vagrant du service Haproxy est effectuée par Ansible.
Cela permet un passage de parametres entre l'environnement de vagrant et ansible;

```Vagrantfile
[...]
  if server["type"] == "haproxy"
            v.vm.provision "ansible" do |ansible|
                ansible.verbose = "vv"
                ansible.extra_vars = {
                  world: world,
                  swarm_bind_port: 2377
                }
                ansible.playbook = "./playbooks/haproxy_playbook.yml"
            end
        end
 [...]
```
Le playbook Ansible pour l'installation du haproxy prend en compte la variable `world` défini précédement dans les parametres de la commande vagrant pour charger le fichier de configuration correspondant à l'environnement attendu.

```yaml
- name: 'Provision Image'
  hosts:  all
  become: true
  tasks:
    - name: install haproxy
      package:
        name: "haproxy"
        state: present
      register: haproxystatus
    - name: configure haproxy
      template:
        dest: /etc/haproxy/haproxy.cfg
        src: "../{{ world }}/conf/haproxy.cfg"
    - name: haproxy service start
      service:
        name: "haproxy"
        state: restarted

```
L'installation du service Haproxy reste basique en soi.

Le fichier de configuration du service HaProxy prie en compte doit etre specfique à l'environnement. 

```conf
global
    daemon
    maxconn 256
defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
frontend http-in
    bind *:80
    default_backend webservers
backend webservers
    balance roundrobin
    # Poor-man's sticky
    # balance source
    # JSP SessionID Sticky
    # appsession JSESSIONID len 52 timeout 3h
    option httpchk
    option forwardfor
    option http-server-close
    server auto 192.168.30.13:80 maxconn 32 check
    server trent 192.168.30.27:80 maxconn 32 check

```



 ### SWARM

C'est la variable `ANSIBLE_GROUP` définie dans le fichier de configuration `vars.vagrantfile.yaml` qui détermine les groupes de machines pour chaque taches lors de l'execution d'execution du playbook `./playbooks/swarm.yml`.


```Vagrantfile
  if server["name"] == ANSIBLE_GROUPS["workers"][WORKERS-1] #playbook when last worker is up
    v.vm.provision "ansible" do |ansible|
      ansible.verbose = "vv"
      ansible.limit = "all"
      ansible.force_remote_user = true
      ansible_ssh_user= "root"
      ansible.groups = ANSIBLE_GROUPS
      ansible.extra_vars = {
        vagrant_primary_manager_ip: servers[1]['eth1'],
        manager_primary: ANSIBLE_GROUPS["managers"][0],
        swarm_bind_port: 2377
      }
      ansible.playbook = "./playbooks/swarm.yml"
    end
  end
```
Connaitre le nombre de workers swarm `WORKERS` va permettre l'execution en une passe du provisionnement de tous les noeuds swarm via Ansible. C'est donc lorsque vagrant provisionnera le dernier noeud du cluster parmis les worker que l'execution du playbook s'effectuera. Il faut pour cela que l'ordre des serveurs `servers` soit identique à l'ordre des nom de machines définies dans `ANSIBLE_GROUPS["workers"]`.

```Vagrantfile
   if server["name"] == ANSIBLE_GROUPS["workers"][WORKERS-1]
   [...]
   end
```


Le playbook s'occupe de l'installation et de la configuration de chaque noeud swarm, selon la configuration donnée par la définition de groupe faite dans la variable ANSIBLE_GROUPE et les limites d'acces ansible sont levées.
```Vagrantfile
      ansible.limit = "all"
      ansible.groups = ANSIBLE_GROUPS
```
L'adresse IP du 1er manageur swarm est passé en parametre pour etre utilisée lors des inscriptions des noeuds swarm. 
```Vagrantfile
    ansible.extra_vars = {
        vagrant_primary_manager_ip: servers[1]['eth1'],
        manager_primary: ANSIBLE_GROUPS["managers"][0],
        swarm_bind_port: 2377
      }
```
Notez la définition de la variable `manager_primary` contenant le nom de la machine du manageur swarm principal qui va permettre la recupération du token d'inscription au cluster swarm  entre les tashes `tasks` du script Ansible `playbooks/swarm.yml`.

### Le playbook swarm (provisionnement du cluster)

Comme indiqué précédement, l'intégralité des machines composants le cluster sont provisionnées par le playbook `playbooks/swarm.yml`. Il intègre dans sa configuration l'utilisation de la variable `ANSIBLE_GROUPS` définie dans le fichier de configuration pour l'installation de l'environnement attendu `vars.vagrantfile.yaml`.

```yaml
ANSIBLE_GROUPS:
  managers:
    - VM-MANAGER1-DCK
  workers:
    - VM-WORKER1-DCK
```
Nous retrouverons donc les varaibles de tableaux `managers` et `worker` dans le playbook;

L'ordre des taches est tres important dans l'execution du playbook et s'appliqueront selon le paramatrage `hosts` établi pour chaque tache.



 ```yaml
 ---
# lecture de l'état du swarm sur le noeud du cluster
- hosts: managers, workers
     [...]
  tasks:
    - name: Check if Swarm Mode is already activated
         [...]

# Initialisation du cluster sur le manageur principal
- hosts: managers[0]
    [...]
  tasks:
    - name: Starting primary swarm manager
         [...]
    - name: Retrieve manager token
         [...]
    - name: Retrieve worker token
         [...]
    - set_fact: # set tokens to variables

# rejoindre le cluser pour les machines manager
- hosts: managers[1:]
     [...]
  tasks:
    - name: Starting secondary swarm managers to join cluster
         [...]

# rejoindre le cluser pour les machines workers
- hosts: workers
     [...]
  tasks:
    - name: Starting swarm workers to join cluster
     [...]

# Labellisation des noeuds
- hosts: managers, workers
     [...]
  tasks:
    - name: Label nodes
     [...]

#lecture de l'etat du cluster
- hosts: managers[0]
     [...]
  tasks:
    - name: Examine the swarm
     [...]

  - set_fact:
      docker_swarm_info: "{{ docker_swarm_result.stdout | from_json }}"

- debug: var=docker_swarm_info.Swarm

- include: network.yml

#installation d'un service dans le cluster
- hosts: managers[0]
   [...]
  tasks:
    - name: check docker-ui
     [...]
    - name: Start docker-ui globally
      [...]
 ```


