-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
--CHECK INSTANCE STATUS:
COL INST FOR A4
COL INSTANCE FOR A10
COL HOST FOR A20
COL DATABASE FOR A10
COl STATE FOR A10
COL VERSION FOR A10
COL ROLE FOR A10
COL STATUS FOR A10
COL MODE FOR A20
COl LOGINS FOR A10
SELECT TO_CHAR(I.INST_ID) "INST", UPPER(INSTANCE_NAME) "INSTANCE", UPPER(HOST_NAME) "HOST", VERSION, DECODE(D.DATABASE_ROLE,'PRIMARY','PRIMARY','PHYSICAL STANDBY','STANDBY','OTHER') ROLE, STATUS "DATABASE", D.OPEN_MODE "MODE", DATABASE_STATUS "STATUS", ACTIVE_STATE "STATE", LOGINS, STARTUP_TIME "STARTUP" FROM GV$INSTANCE I , GV$DATABASE D WHERE I.INST_ID = D.INST_ID;
=========================================================================================================================================
--CONNECT TO CATALOG:
connect target /
connect rcvcat rcat_teq_122/Atlantic_cit8@prman
=========================================================================================================================================
--REMOVE DB FROM CATALOG:
SELECT NAME, DB_KEY, DBINC_KEY, DBID, RESETLOGS_TIME FROM RCAT_TEQ_122.RC_DATABASE WHERE NAME LIKE '%QEPSP%' ORDER BY 5;
$ rman
connect rcvcat rcat_teq_122/Atlantic_cit8@prman

export TNS_ADMIN=/db01/static/oradba/bin/rman/
export TNS_ADMIN=/orasw/static/oradba/bin/rman
connect rcvcat /@trmanp1
RMAN> set dbid 1523174064
RMAN> LIST BACKUP SUMMARY;
RMAN> DELETE BACKUP NOPROMPT;
RMAN> UNREGISTER DATABASE;
=========================================================================================================================================
--ACCESS FED TMO DATABASES:
sudo su - oracle -c /oracle/g01/admin/sysoper/bin/fedmenu.sh
sudo -u oracle /orasw/static/oradba/sysoper/bin/sysopermenu.sh pratp
$ORACLE_SID
=========================================================================================================================================
--ACCESS FED TMO DATABASES II:
export ORACLE_HOME=/orasw/app/oracle/product/19/db
export PATH=$PATH:$ORACLE_HOME/bin:/usr/local/bin
. oraenv
sqlplus /nolog
conn ROLIVEI4/"8V!WB5TdgoKiV2#IuPhY58uBU98j8$" | "KgNMsXUh5jWH6V3JAPZdp#8C!9rxkR"
conn ROLIVEI4/"JGDAcNb5wXK8B2#!SReWj6TLmhqdpg"
=========================================================================================================================================
--SEND EMAIL FROM AIX SERVER
uuencode listener_pcdep.log listener_pcdep.log | mailx -s "listener_pcdep.log" rafael.oliveira@t-mobile.com
=========================================================================================================================================
-- GOLDENGATE
--set gg env
sudo -iu ggsadm
./ggsci
info all
stop/start replicat/extract/manager <nome do objeto>
=========================================================================================================================================
--Stop/Start Databases:
. oraenv (instance)

srvctl stop database -d pcdep
srvctl start database -d psocrp

srvctl stop instance -d pjpyp -i pjpyp1
srvctl start instance -d psocrp -i psocrp2

srvctl stop listener -l LISTENER_PJPYP -n ppolabpms00001
srvctl start listener -l LISTENER_PSOCRP -n ppolabpms00001
=========================================================================================================================================
--Stop/Start Databases SYSOPER:
sudo -u root /orasw/app/19/grid/bin/crsctl stop crs

sudo -u oracle /orasw/app/19/grid/bin/srvctl stop database -d <db>
=========================================================================================================================================
--INICIAR/PARAR BLACKOUT I
-- INICIAR
/nfs/infra/oracle/scripts/maintenance/start_blackout_agent.sh 43200

-- PARAR
/nfs/infra/oracle/scripts/maintenance/stop_blackout_agent.sh
=========================================================================================================================================
--INICIAR/PARAR BLACKOUT II
-- INICIAR
. ./setenv.sh
start_blackout_agent.sh 43200

-- PARAR
. ./setenv.sh
stop_blackout_agent.sh
=========================================================================================================================================
--INICIAR/PARAR BLACKOUT III
-- INICIAR
/nfs/infra/oracle/scripts/maintenance/start_blackout_agent_indefinite.sh

-- PARAR
/nfs/infra/oracle/scripts/maintenance/stop_blackout_agent_indefinite.sh
=========================================================================================================================================
. oraenv (+ASMx)
 
srvctl stop asm -f
sudo crsctl stop has
 
srvctl start asm -f
=========================================================================================================================================
--SET OEM AGENT HOME TO CHECK STATUS:
--ORACLE_HOME=$AGENT_HOME
export ORACLE_HOME=/db01/static/app/oracle/agent13c/agent_13.4.0.0.0/
export ORACLE_HOME=/orasw/static/app/oracle/agent13c/agent_13.4.0.0.0/
export PATH=$ORACLE_HOME/bin:$PATH
emctl status agent
=========================================================================================================================================
--Find Alertlog:
select value from v$diag_info where name like '%Trace%';
=========================================================================================================================================
--Check which table is causing the error (ORA-00001: unique constraint (constraint_name) violated):
SELECT DISTINCT TABLE_NAME
FROM DBA_INDEXES
WHERE OWNER = 'OWNER_NAME' AND INDEX_NAME = 'CONSTRAINT_NAME';
=========================================================================================================================================
--Kill datapump job:
DECLARE
   h1 NUMBER;
BEGIN
   h1 := DBMS_DATAPUMP.ATTACH('SYS_EXPORT_FULL_03','SYSTEM');
   DBMS_DATAPUMP.STOP_JOB (h1,1,0);
END;
=========================================================================================================================================
--CHECK DATABASE SIZE:
SELECT "RESERVED_SPACE(GB)", "RESERVED_SPACE(GB)" - "FREE_SPACE(GB)" "USED_SPACE(GB)","FREE_SPACE(GB)"
FROM(SELECT (SELECT SUM(BYTES/(1014*1024*1024)) FROM DBA_DATA_FILES) "RESERVED_SPACE(GB)", (SELECT SUM(BYTES/(1024*1024*1024)) FROM DBA_FREE_SPACE) "FREE_SPACE(GB)" FROM DUAL);
=========================================================================================================================================
--Growth of the database in a monthly basis , This data is from the control file :
select to_char(creation_time, 'RRRR Month') "Month",
sum(bytes)/1024/1024 "Growth in Meg"
from sys.v_$datafile
where creation_time > SYSDATE-365
group by to_char(creation_time, 'RRRR Month');
=========================================================================================================================================
--Specific Segment Growth in the past days based on the AWR snapshots :
column "Percent of Total Disk Usage" justify right format 999.99
column "Space Used (MB)" justify right format 9,999,999.99
column "Total Object Size (MB)" justify right format 9,999,999.99
set linesize 150
set pages 80
set feedback off
select * from (select to_char(end_interval_time, 'Mon/DD/YYYY') mydate, sum(space_used_delta) / 1024 / 1024 "Space used (MB)", avg(c.bytes) / 1024 / 1024 "Total Object Size (MB)",
round(sum(space_used_delta) / sum(c.bytes) * 100, 2) "Percent of Total Disk Usage"
from
dba_hist_snapshot sn,
dba_hist_seg_stat a,
dba_objects b,
dba_segments c
where begin_interval_time > trunc(sysdate) - &days_back
and sn.snap_id = a.snap_id
and b.object_id = a.obj#
and b.owner = c.owner
and b.object_name = c.segment_name
and c.segment_name = '&segment_name'
group by to_char(end_interval_time, 'Mon/DD/YYYY'))
order by to_date(mydate, 'Mon/DD/YYYY');
=========================================================================================================================================
--Growth of Specific database Schema in the past days based on the AWR snapshots :
set feedback off
set pages 80
set linesize 150
ttitle "Total Disk Used"
select sum(space_used_delta) / 1024 / 1024 "Space used (M)", sum(c.bytes) / 1024 / 1024 "Total Schema Size (M)",
round(sum(space_used_delta) / sum(c.bytes) * 100, 2) || '%' "Percent of Total Disk Usage"
from
dba_hist_snapshot sn,
dba_hist_seg_stat a,
dba_objects b,
dba_segments c
where end_interval_time > trunc(sysdate) - &days_back
and sn.snap_id = a.snap_id
and b.object_id = a.obj#
and b.owner = c.owner
and b.object_name = c.segment_name
and c.owner = '&schema_name'
and space_used_delta > 0;
=========================================================================================================================================
--Growth of Specific database Schema per Object Type in the past days based on the AWR snapshots :
title "Total Disk Used by Object Type"
select c.segment_type, sum(space_used_delta) / 1024 / 1024 "Space used (M)", sum(c.bytes) / 1024 / 1024 "Total Space (M)",
round(sum(space_used_delta) / sum(c.bytes) * 100, 2) || '%' "Percent of Total Disk Usage"
from
dba_hist_snapshot sn,
dba_hist_seg_stat a,
dba_objects b,
dba_segments c
where end_interval_time > trunc(sysdate) - &days_back
and sn.snap_id = a.snap_id
and b.object_id = a.obj#
and b.owner = c.owner
and b.object_name = c.segment_name
and space_used_delta > 0
and c.owner = '&schema_name'
group by rollup(segment_type);
=========================================================================================================================================
set heading off;
set line 400
select INPUT_TYPE || ' Bakup ' || initcap(STATUS) || ' on ' ||
  to_char(START_TIME,'mm/dd/yyyy') || ' in ' || TIME_TAKEN_DISPLAY  || ', Backup size ' || OUTPUT_BYTES_DISPLAY || 
  ', Compression ' || round(COMPRESSION_RATIO,1) "Compression"
from v$rman_backup_job_details
where 
START_TIME > sysdate - &days and
INPUT_TYPE like '%FULL%'
OR  INPUT_TYPE like '%INCR%'
order by session_key desc;
=========================================================================================================================================
-- tamanho total do BD I
SELECT D.TABLESPACE_NAME "NAME", SUM(((A.BYTES - DECODE(F.BYTES, NULL, 0, F.BYTES)) / 1048576)) "TOTAL_UTILIZADO (MB)"
FROM SYS.DBA_TABLESPACES D, SYS.SM$TS_AVAIL A, SYS.SM$TS_FREE F
WHERE D.TABLESPACE_NAME = A.TABLESPACE_NAME
AND F.TABLESPACE_NAME (+) = D.TABLESPACE_NAME
GROUP BY    ROLLUP(D.TABLESPACE_NAME);
=========================================================================================================================================
-- tamanho total do BD I
SELECT
"RESERVED_SPACE(GB)", "RESERVED_SPACE(GB)" - "FREE_SPACE(GB)" "USED_SPACE(GB)","FREE_SPACE(GB)"
FROM(
SELECT
(SELECT SUM(BYTES/(1014*1024*1024)) FROM DBA_DATA_FILES) "RESERVED_SPACE(GB)",
(SELECT SUM(BYTES/(1024*1024*1024)) FROM DBA_FREE_SPACE) "FREE_SPACE(GB)"
FROM DUAL );
SELECT
"RESERVED_SPACE(GB)", "RESERVED_SPACE(GB)" - "FREE_SPACE(GB)" "USED_SPACE(GB)","FREE_SPACE(GB)"
FROM(
SELECT
(SELECT SUM(BYTES/(1014*1024*1024)) FROM DBA_DATA_FILES) "RESERVED_SPACE(GB)",
(SELECT SUM(BYTES/(1024*1024*1024)) FROM DBA_FREE_SPACE) "FREE_SPACE(GB)"
FROM DUAL );
=========================================================================================================================================
--CHECK TABLE PARTITIONS:
select owner,object_name,subobject_name,to_char(created,'DD.MM.YYYY HH24:MI:SS') from dba_objects where object_type='TABLE PARTITION' and trunc(created) = trunc(sysdate);
select owner,object_name,subobject_name,to_char(created,'DD.MM.YYYY HH24:MI:SS') from dba_objects where object_type='TABLE PARTITION' and owner not in ('SYS', 'AUDSYS','OPS$ORACLE','SYSTEM');