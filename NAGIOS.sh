#mod gearman worker
#rancher & adicionar worker e clientes no godfather

#knowledge base https://tecadmin.net/install-nrpe-on-centos-rhel/
#1 proc / 2gb ram / 30gb disco


docker run -d --name gearman-worker-lb2 -e HOSTGROUP=COASUL  -e SERVER=52.205.181.109:4730 lb2consultoria/mod_gearman_worker:oracle


V_REL=`cat /etc/redhat-release |grep -o '[0-9]*' | sed -n 1p`
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${V_REL}.noarch.rpm
yum --enablerepo=epel -y install nrpe nagios-plugins
V_NRPE=`find /etc/ -type f -name nrpe.cfg`
V_AHOST=`cat $V_NRPE | grep allowed_hosts`
V_IP=`hostname -I | awk '{print $1}'`
echo "$(awk '{if (/'$V_AHOST'/) {$0=$0 "',$V_IP'"}; print}' $V_NRPE)" > $V_NRPE