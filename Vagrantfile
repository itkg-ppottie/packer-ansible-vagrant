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
private_registry = vagrant_yaml['private_registry']


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.forward_agent = true
  config.ssh.username = 'debian'
  config.ssh.password = 'debian'
  config.vm.synced_folder ".","/vagrant", disabled:true
    servers.each_with_index do | (hostname,server),index|
      config.vm.define hostname do |v|
        v.vm.box  = server["box"]
        v.vm.hostname = hostname

        v.vm.network :private_network, ip: server["eth1"]
        v.vm.provider "virtualbox" do |vb|
            vb.customize ["modifyvm", :id, "--memory", server["mem"]]
            vb.customize ["modifyvm", :id, "--cpus", server["cpu"]]
        end
        if server["type"] == "postgres"
          v.vm.network "forwarded_port", guest: 5432, host: 5432
        end
        if server["type"] == "mysql"
          v.vm.network "forwarded_port", guest: 3306, host: 3306
        end

        if hostname == ANSIBLE_GROUPS["workers"][WORKERS-1] #playbook when last worker is up
          v.vm.provision "ansible" do |ansible|
              ansible.verbose = "vv"
              ansible.limit = "all"
              ansible.force_remote_user = true
              ansible_ssh_user= "root"
              ansible.groups = ANSIBLE_GROUPS
              ansible.extra_vars = {
                ansible_python_interpreter:"/usr/bin/python3",
                vagrant_primary_manager_ip: servers[ANSIBLE_GROUPS["managers"][0]]['eth1'],
                manager_primary: ANSIBLE_GROUPS["managers"][0],
                world: world,
                servers: servers,
                username: config.ssh.username,
                swarm_bind_port: 2377,
                private_registry: private_registry
              }
              ansible.playbook = "./playbooks/playbooks.yml"
          end
        end
      end
    end
end
