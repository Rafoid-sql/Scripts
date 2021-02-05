export VDATE=`date '+%d-%m-%Y-%H:%M:%S'`
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_UNQNAME=AJR; export ORACLE_UNQNAME
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_SID=prd; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH; export PATH
#export NLS_LANG="BRAZILIAN PORTUGUESE_BRAZIL.WE8ISO8859P1"
$ORACLE_HOME/bin/sqlplus /nolog<<EOO
conn /as sysdba
spool '/home/oracle/scripts/bin/logs_aplicados/prd_aplicados_$VDATE.log'
recover database using backup controlfile until cancel;
auto
spool off
quit
EOO

