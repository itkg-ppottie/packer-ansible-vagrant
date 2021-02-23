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
            v.vm.provision "ansible" do |ansible|
                ansible.verbose = "vv"
                ansible.force_remote_user = true
                ansible_ssh_user= "root"
                ansible.groups = ANSIBLE_GROUPS
                ansible.extra_vars = {
                  vagrant_primary_manager_ip: vagrant_primary_manager_ip,
                  swarm_bind_port: 2377
                }
                ansible.playbook = "./playbooks/swarm.yml"
            end
        end
      end
    end
end
