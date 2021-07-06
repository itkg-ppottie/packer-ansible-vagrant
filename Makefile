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


prod_inventory: INVENTORY = configs/prod/inventory.yml
prod_inventory: add_inventory

preprod_inventory: INVENTORY = configs/preprod/inventory.yml
preprod_inventory: add_inventory

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

deploy-preprod-kilometers: ## Deploy kilometers api on staging
deploy-preprod-kilometers: preprod_inventory kilometers_deploy 

deploy-preprod-docker-prune: ## deploy docker-prune stack to clean node all 24h on staging
deploy-preprod-docker-prune: preprod_inventory docker_prune_deploy


deploy-preprod-monitoring: ## Deploy all metrics,monitoring,logs services on staging
deploy-preprod-monitoring: preprod_inventory monitoring_deploy
	
deploy-preprod-fluentd: ## Deploy fluentd on staging
deploy-preprod-fluentd: preprod_inventory fluentd_deploy

deploy-preprod-node_exporter: ## Deploy fluentd on staging
deploy-preprod-node_exporter: preprod_inventory node_exporter_deploy

deploy-preprod-traefik: ## Deploy traefik on staging
deploy-preprod-traefik: preprod_inventory traefik_deploy


deploy-preprod-cadvisor: ## Deploy cadvisor on staging
deploy-preprod-cadvisor: preprod_inventory cadvisor_deploy

deploy-prod-kilometers: ## Deploy kilometers api on production
deploy-prod-kilometers: prod_inventory kilometers_deploy 

deploy-prod-docker-prune: ## deploy docker-prune stack to clean node all 24h on production
deploy-prod-docker-prune: prod_inventory docker_prune_deploy

deploy-prod-monitoring: ## Deploy all metrics,monitoring,logs services on production
deploy-prod-monitoring: prod_inventory monitoring_deploy
	
deploy-prod-fluentd: ## Deploy fluentd on production
deploy-prod-fluentd: prod_inventory fluentd_deploy

deploy-prod-node_exporter: ## Deploy fluentd on production
deploy-prod-node_exporter: prod_inventory node_exporter_deploy

deploy-prod-traefik: ## Deploy traefik on production
deploy-prod-traefik: prod_inventory traefik_deploy

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

