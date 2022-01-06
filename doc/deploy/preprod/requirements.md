# applications necessaires sur chaque noeuds

docker
docker swarm (initialisé)
docker-compose
glusterfs (installé & configuré)
elasticsearch apm  (installé & configuré)

il faut:
 - pouvoir deployer  le monitoring dans le cluster
 - deployer/arreter/mettre a jour une application ngc dans le cluster



Le cluster de staging: 
        X masters
        Y workers

la 1er fois il faut 

activer les metrics sur docker 
    - actver metrics du deamon docker sur chaque noeuds du cluster
    - visualizer
    - cadvisor
    - node-exporter
    - docker-exporter
    - prometheus
    - grafana



deployement
tester les droits et acces :
    ansible check cluster staging-swarm
deployer le monitoring    
    ansible deploy monitoring staging-swarm 

deployer une application NGC
    ansible deploy api-kilometers staging-swarm

deployer une maj d'une application NGC
    ansible upgrade [VERSION] [STACK] [SERVICE] [ENVIRONMENT]
    ansible upgrade VERSION api-kilmeters web staging-swarm

ansible stop [SERVICE] [ENVIRONMENT]



