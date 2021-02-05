export ORACLE_BASE=/u01/app/oracle
export NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
export ORACLE_HOME=$ORACLE_BASE/product/10.2.0/db_1
export PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORACLE_SID=tasy
export ARQ_LOG=/home/oracle/CheckLogicalTasy_${ORACLE_SID}_`date '+%d%m%Y_%H%M'`.log

echo 'Iniciando validate check logical database - ${ORACLE_SID}'  >> $ARQ_LOG
rman target / <<EOF 1>> ${ARQ_LOG} 2>> ${ARQ_LOG}
show all;
run {
validate check logical database;
}
exit
EOF


backup validate logical database


 load average: 1.25, 1.35, 1.20


Every 5.0s: df -hTP                                                                                                           Mon Sep  9 11:51:38 2019

Filesystem    Type    Size  Used Avail Use% Mounted on
/dev/sdc1     ext3     76G   16G   57G  22% /
/dev/sdb3     ext3    440G  353G   87G  81% /u01
/dev/sda1     ext3    1.8T  380G  1.4T  23% /backup
/dev/sdb1     ext3    487M   27M  435M   6% /boot
tmpfs        tmpfs     16G     0   16G   0% /dev/shm
	