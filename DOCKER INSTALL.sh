
# Instalar no CentOS:
yum update
yum install yum-utils
yum-config-manager --enable *addons
yum install docker-engine
systemctl enable docker
systemctl start docker
docker pull lb2consultoria/mod_gearman_worker:oracle
docker run -d --name gearman-worker -e HOSTGROUP=PADO -e SERVER=52.205.181.109:4730 lb2consultoria/mod_gearman_worker:oracle


#Conferir:
docker ps
ps -ef | grep worker