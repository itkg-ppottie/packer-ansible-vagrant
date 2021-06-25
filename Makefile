ifndef VERBOSE
.SILENT:
endif
.PHONY:
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[3m

DELOY_CDMD = ansible-playbook   -u ngc -e "ansible_python_interpreter=/usr/bin/python3" 

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

deploy-preprod-kilometers: 
	${DELOY_CDMD} -i configs/preprod/inventory.yml   playbooks/ngc/api-kilometers/api-kilometers.yml

deploy-preprod-monitoring: ## Deploy all metrics,monitoring,logs services on staging
deploy-preprod-monitoring:
	${DELOY_CDMD} -i configs/preprod/inventory.yml  playbooks/monitoring/monitoring.yml

deploy-preprod-fluentd: ## Deploy fluentd on staging
deploy-preprod-fluentd:
	${DELOY_CDMD} -i configs/preprod/inventory.yml playbooks/monitoring/fluentd.yml

deploy-preprod-node-exporter: ## Deploy fluentd on staging
deploy-preprod-node-exporter:
	${DELOY_CDMD} -i configs/preprod/inventory.yml playbooks/monitoring/node-exporter.yml

deploy-preprod-traefik: ## Deploy traefik on staging
deploy-preprod-traefik:
	${DELOY_CDMD} -i configs/preprod/inventory.yml playbooks/traefik.yml
##
help:banner

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?## .*$$)|(^## )' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/' | sed 's/Makefile.\(\s\)*//'
.PHONY: help

