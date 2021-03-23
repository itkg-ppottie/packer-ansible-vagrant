ifndef VERBOSE
.SILENT:
endif
.PHONY:
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[3m

install_api_kilometer:
	

install:
	ansible-galaxy collection install -r requirements.yml

build: ## build box and create cluster infrastructure
build:
	ansible-playbook build-vm-cluster-swarm.yml

rebuild: ## rebuild cluster (vagrant provision)
rebuild:
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

deploy-kilometer: 
	docker stack deploy --with-registry-auth --compose-file docker-compose.yml api_kilometer


##
help:banner

.DEFAULT_GOAL := help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?## .*$$)|(^## )' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/' | sed 's/Makefile.\(\s\)*//'
.PHONY: help
