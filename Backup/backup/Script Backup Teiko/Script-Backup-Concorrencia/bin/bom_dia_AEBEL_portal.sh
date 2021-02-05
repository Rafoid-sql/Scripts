#!/bin/sh

# Definicao de variaveis
DATE=`date +'%d-%m-%Y'`
export ORACLE_BASE="/u01/app/oracle"
export ORACLE_SID="portal"
export ORACLE_HOME="$ORACLE_BASE/product/11.2.0/db_1"
export SCRIPTLOG=/home/oracle/scripts/bin/logs/bom_dia_PORTAL_`date +'%d-%m-%Y'`.log

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "******************************** ESPACO EM DISCO *******************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
df -h >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "******************************** TEMPO LIGADO **********************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
uptime >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "******************************** ULTIMO ARCHIVE ********************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
set echo off
set verify off
set feedback off
ttitle off
set heading on
col host_name format a30
set lines 200
set pagesize 80
SPOOL '/home/oracle/scripts/bin/ultimoarc.log';
select max(sequence#) from v\$archived_log where deleted = 'NO';
SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/ultimoarc.log' >> $SCRIPTLOG


echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "***************** ULTIMOS ARCHIVES NO REPOSITORIO DE BACKUP ********************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
ls -lht /u02/portal/archives | head -50 >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "******************************** INSTANCIAS ************************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
set echo off
set verify off
set feedback off
ttitle off
set heading on
col host_name format a30
set lines 200
set pagesize 80
SPOOL '/home/oracle/scripts/bin/instancias.log';
SELECT INST_ID, INSTANCE_NAME, HOST_NAME, VERSION, TO_CHAR(STARTUP_TIME,'DD-MM-YYYY HH24:MI:ss') STARTUP_TIME, INSTANCE_ROLE, STATUS 
FROM GV\$INSTANCE ORDER BY INST_ID;

SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/instancias.log' >> $SCRIPTLOG


echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "******************************* TABLESPACES ************************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
SET LINESIZE 350
SET PAGES 200
COL TABLESPACE_NAME FORMAT A35
COL FILE_NAME FORMAT A66
COL AUTOEXTENSIBLE  FORMAT A4

SPOOL '/home/oracle/scripts/bin/tablespaces.log';

SELECT A.TABLESPACE_NAME "TABLESPACE NAME",
ROUND(A.BYTES/1024/1024) "MB ALLOCATED",
ROUND(A.BYTESTOTAL/1024/1024) "AUTO EXTENSIBLE",
ROUND((A.BYTES-NVL(B.BYTES, 0)) / 1024 / 1024) "MB USED",
NVL(ROUND(B.BYTES / 1024 / 1024), 0) "MB FREE",
ROUND(((A.BYTES-NVL(B.BYTES, 0))/A.BYTES)*100,2) "% USED",
ROUND((1-((A.BYTES-NVL(B.BYTES,0))/A.BYTES))*100,2) "% FREE"
FROM (SELECT TABLESPACE_NAME,
     SUM(BYTES) BYTES,
     sum(MAXBYTES) BYTESTOTAL
     FROM DBA_DATA_FILES
     GROUP BY TABLESPACE_NAME) A,
(SELECT TABLESPACE_NAME,
SUM(BYTES) BYTES
FROM SYS.DBA_FREE_SPACE
GROUP BY TABLESPACE_NAME) B
WHERE A.TABLESPACE_NAME = B.TABLESPACE_NAME (+)
ORDER BY 7,1;
SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/tablespaces.log' >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "******************************** CONEXOES **************************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
set echo off
set verify off
set feedback off
ttitle off
set heading on
col host_name format a30
set lines 200
set pagesize 80
SPOOL '/home/oracle/scripts/bin/conexoes.log';
SELECT USERNAME, COUNT(*) 
FROM GV\$SESSION 
WHERE lower(OSUSER) <> 'oracle' 
GROUP BY USERNAME
ORDER BY 1 DESC;

SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/conexoes.log' >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "**************************** ARCHIVES GERADOS POR DIA **************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
set echo off
set verify off
set feedback off
ttitle off
set heading on
col host_name format a30
set lines 200
set pagesize 80
SPOOL '/home/oracle/scripts/bin/archives.log';
select 
    trunc(FIRST_TIME,'dd') data_hora,
    count(*) qtd, 
    trunc(sum(blocks * block_size/1024/1024/1024)) GB
from gv\$archived_log
where to_char(trunc(FIRST_TIME,'dd'),'YYYYMM') = to_char(sysdate,'YYYYMM')
group by trunc(FIRST_TIME,'dd')
order by trunc(FIRST_TIME,'dd') desc;

SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/archives.log' >> $SCRIPTLOG


echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "**************************** RESUMO BACKUPS RMAN *******************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
set echo off
set verify off
set feedback off
ttitle off
set heading on
col host_name format a30
set lines 200
set pagesize 80
col "STATUS" for a10
col "TIME_TAKEN_DISPLAY" for a10
col "INPUT_BYTES_DISPLAY" for a10
SPOOL '/home/oracle/scripts/bin/rman.log';
SELECT TO_CHAR(START_TIME,'DD/MM HH24:MI') START_TIME, TO_CHAR(END_TIME,'DD/MM HH24:MI') END_TIME, STATUS, TIME_TAKEN_DISPLAY, INPUT_BYTES_DISPLAY
FROM V\$RMAN_BACKUP_JOB_DETAILS
WHERE START_TIME >= SYSDATE-7
AND STATUS<>'RUNNING'
order by to_date(start_time,'DD/MM HH24:MI');

SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/rman.log' >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "**************************** TAMANHO DO DATABASE *******************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG

$ORACLE_HOME/bin/sqlplus -S '/ as sysdba' << EOF
set echo off
set verify off
set feedback off
ttitle off
set heading on
col host_name format a30
set lines 200
set pagesize 80
SPOOL '/home/oracle/scripts/bin/sizedb.log';
select to_char(sum(bytes) / 1024 / 1024 / 1024,'9G999G999D9') "Tamanho GB"
from (
  select sum(bytes) bytes from dba_data_files
  union all 
  select sum(bytes) bytes from dba_temp_files 
  union all
  select sum(bytes * members) from v\$log 
  union all
  select sum(block_size * file_size_blks) from v\$controlfile
);

SPOOL off;
exit
EOF
cat '/home/oracle/scripts/bin/sizedb.log' >> $SCRIPTLOG

echo >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
echo "************************ ALERT LOG INCIDENTS ***********************************" >> $SCRIPTLOG
echo "********************************************************************************" >> $SCRIPTLOG
adrci exec="show incident -orderby create_time asc" >> $SCRIPTLOG
echo >> $SCRIPTLOG

rm /home/oracle/scripts/bin/*.log

# *** Envia log por e-mail ************************
DE="dba@s1ti.com.br"
USUARIO="dba@s1ti.com.br"
SENHA='!@#DbaS1ti'
SMTP="email-ssl.com.br"
PARA="silviodauricio@gmail.com"
ASSUNTO="AEBEL-PORTAL | BOM DIA"
ANEXO="$SCRIPTLOG"
/home/oracle/scripts/bin/sendEmail/sendEmail -f $DE -t $PARA -u $ASSUNTO -a $ANEXO -s $SMTP:587 -xu $USUARIO -xp $SENHA  -m $ASSUNTO


