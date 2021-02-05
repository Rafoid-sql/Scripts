#!/bin/sh 

export ORACLE_SID=prd
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_UNQNAME=prd
export ORACLE_HOSTNAME=dborastdb
export PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH; export PATH
#export PATH=$ORACLE_HOME/bin:/usr/bin:/etc:/usr/sbin:/usr/ucb:$HOME/bin:/usr/bin/X11:/sbin:
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export VDATE=`date '+%y%m%d_%H'`

export RMANREPORTS=/home/oracle/scripts/bin/rman_reports/prd_crosscheck_$VDATE.log

$ORACLE_HOME/bin/rman <<EOF
connect target /;
SPOOL log to '/home/oracle/scripts/bin/rman_reports/prd_crosscheck_$VDATE.log' ;
set echo on;
list backup of database summary completed between 'sysdate-4' and 'sysdate' ;
list backup of archivelog all summary completed between 'sysdate-4' and 'sysdate' ;
list backup of controlfile summary completed between 'sysdate-4' and 'sysdate' ;
report obsolete;
crosscheck archivelog all ;
crosscheck backup;
delete  noprompt expired archivelog all;
delete force noprompt expired backup;
delete force noprompt obsolete ;
spool log off ;
quit ;
EOF
echo "Completed  crosscheck  ......" >> ${RMANREPORTS}

