ifndef VERBOSE
.SILENT:
endif
.PHONY:
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[3m

DELOY_CMD = ansible-playbook   -u ngc -e "ansible_python_interpreter=/usr/bin/python3" 

update_etc_hosts: ## update /etc/hosts file with inventory file
update_etc_hosts:
	ansible-playbook etc_hosts.yml -K
	
install: ## install ansible module and collection
install:
	ansible-galaxy install geerlingguy.glusterfs
	ansible-galaxy collection install -r requirements.yml

build: ## build box and create cluster infrastructure
build:
	ansible-playbook build-vm-cluster-swarm.yml

rebuild-local: ## rebuild cluster (vagrant provision)
rebuild-local:
	vagrant provision

start: ## start cluster
start:
	vargrant up

destroy: ## destroy cluster
	vagrant destroy

stop: ## stop VM clusters
stop:
	vagrant stop




banner:
	printf "\n"
	printf "\033[32m ███████╗██╗    ██╗ █████╗ ██████╗ ███╗   ███╗     ██████╗██╗     ██╗   ██╗███████╗████████╗███████╗██████╗ \033[0m\n"
	printf "\033[32m ██╔════╝██║    ██║██╔══██╗██╔══██╗████╗ ████║    ██╔════╝██║     ██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗\033[0m\n"
	printf "\033[32m ███████╗██║ █╗ ██║███████║██████╔╝██╔████╔██║    ██║     ██║     ██║   ██║███████╗   ██║   █████╗  ██████╔╝\033[0m\n"
	printf "\033[32m ╚════██║██║███╗██║██╔══██║██╔══██╗██║╚██╔╝██║    ██║     ██║     ██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗\033[0m\n"
	printf "\033[32m ███████║╚███╔███╔╝██║  ██║██║  ██║██║ ╚═╝ ██║    ╚██████╗███████╗╚██████╔╝███████║   ██║   ███████╗██║  ██║\033[0m\n"
	printf "\033[32m ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═════╝╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝\033[0m\n"
	printf "\033[32m                                                                                                            \033[0m\n"

develop_inventory: INVENTORY = configs/develop/inventory.yml
develop_inventory: add_inventory

production_inventory: INVENTORY = configs/production/inventory.yml
production_inventory: add_inventory

staging_inventory: INVENTORY = configs/staging/inventory.yml
staging_inventory: add_inventory

add_inventory:
	$(eval DELOY_CMD := $(DELOY_CMD) -i ${INVENTORY})

deploy:
	echo "${DELOY_CMD}  ${PLAYBOOK}"
	${DELOY_CMD}  ${PLAYBOOK}

kilometers_deploy: PLAYBOOK = playbooks/ngc/api-kilometers/api-kilometers.yml 
kilometers_deploy: deploy

docker_prune_deploy: PLAYBOOK = playbooks/docker-prune.yml
docker_prune_deploy: deploy
	
monitoring_deploy: PLAYBOOK = playbooks/monitoring/monitoring.yml
monitoring_deploy: deploy

fluentd_deploy: PLAYBOOK = playbooks/monitoring/fluentd.yml
fluentd_deploy: deploy

node_exporter_deploy: PLAYBOOK = playbooks/monitoring/node-exporter.yml
node_exporter_deploy: deploy

cadvisor_deploy: PLAYBOOK = playbooks/monitoring/cadvisor.yml
cadvisor_deploy: deploy

traefik_deploy: PLAYBOOK = playbooks/traefik.yml
traefik_deploy: deploy

firstime_deploy: PLAYBOOK = playbooks/deploy-cluster.yml
firstime_deploy: deploy

deploy-staging-kilometers: ## Deploy kilometers api on staging
deploy-staging-kilometers: staging_inventory kilometers_deploy 

deploy-staging-docker-prune: ## deploy docker-prune stack to clean node all 24h on staging
deploy-staging-docker-prune: staging_inventory docker_prune_deploy


deploy-staging-monitoring: ## Deploy all metrics,monitoring,logs services on staging
deploy-staging-monitoring: staging_inventory monitoring_deploy
	
deploy-staging-fluentd: ## Deploy fluentd on staging
deploy-staging-fluentd: staging_inventory fluentd_deploy

deploy-staging-node_exporter: ## Deploy fluentd on staging
deploy-staging-node_exporter: staging_inventory node_exporter_deploy

deploy-staging-traefik: ## Deploy traefik on staging
deploy-staging-traefik: staging_inventory traefik_deploy


deploy-staging-cadvisor: ## Deploy cadvisor on staging
deploy-staging-cadvisor: staging_inventory cadvisor_deploy

deploy-production-kilometers: ## Deploy kilometers api on production
deploy-production-kilometers: production_inventory kilometers_deploy 

deploy-production-docker-prune: ## deploy docker-prune stack to clean node all 24h on production
deploy-production-docker-prune: production_inventory docker_prune_deploy

deploy-production-monitoring: ## Deploy all metrics,monitoring,logs services on production
deploy-production-monitoring: production_inventory monitoring_deploy
	
deploy-production-fluentd: ## Deploy fluentd on production
deploy-production-fluentd: production_inventory fluentd_deploy

deploy-production-node_exporter: ## Deploy fluentd on production
deploy-production-node_exporter: production_inventory node_exporter_deploy

deploy-production-traefik: ## Deploy traefik on production
deploy-production-traefik: production_inventory traefik_deploy

deploy-production-portainer: ## Deploy portainer on production
deploy-production-portainer: production_inventory portainer_deploy

deploy-production-firsttime: ## Init production cluster
deploy-production-firsttime: production_inventory firstime_deploy

##
help:banner

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?## .*$$)|(^## )' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/' | sed 's/Makefile.\(\s\)*//'
.PHONY: help

