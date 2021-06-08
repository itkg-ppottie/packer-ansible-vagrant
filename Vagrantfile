require 'getoptlong'
require 'yaml'

opts = GetoptLong.new(
  [ '--environment', GetoptLong::OPTIONAL_ARGUMENT ]
)

world='vm-local'

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
vagrantfile = "configs/#{world}/vagrant.inventory.yaml"
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
url_domain =  vagrant_yaml['url_domain']
prefix_url_domain = vagrant_yaml['prefix_url_domain']
LAST = vagrant_yaml['LAST']

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

        if server["forward_ports"].kind_of?(Array)
          server["forward_ports"].each  do |forward_ports|
            v.vm.network "forwarded_port", guest: forward_ports, host: forward_ports
          end
        end

        if hostname == LAST #playbook when last worker is up
          v.vm.provision "ansible" do |ansible|
              ansible.verbose = true
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
                private_registry: private_registry,
                URL_DOMAIN: url_domain,
                PREFIX_URL_DOMAIN: prefix_url_domain,
                ELK_LOGS_HOST: servers[ANSIBLE_GROUPS["elk-logs"][0]]['eth1'],
                LAFA_COMMON_HOST: servers[ANSIBLE_GROUPS['databases-postgresql'][0]]['eth1'],
                POSTGRESQL_HOST: servers[ANSIBLE_GROUPS['databases-mysql'][0]]['eth1'],
                APM_URL: servers[ANSIBLE_GROUPS['elk-apm'][0]]['eth1'],
                CADVISOR_DOCKER_URL: vagrant_yaml['CADVISOR_DOCKER_URL']
              }
              ansible.playbook = "./playbooks/playbooks.yml"
          end
        end
      end
    end
end
