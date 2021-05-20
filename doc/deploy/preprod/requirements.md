# applications necessaires sur chaque noeuds

docker
docker swarm (initialisé)
docker-compose
glusterfs (installé & configuré)


il faut:
 - pouvoir deployer  le monitoring dans le cluster
 - deployer/arreter/mettre a jour une application ngc dans le cluster



Le cluster de preprod: 
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
    ansible check cluster preprod
deployer le monitoring    
    ansible deploy monitoring preprod 

deployer une application NGC
    ansible deploy api-kilometer preprod


