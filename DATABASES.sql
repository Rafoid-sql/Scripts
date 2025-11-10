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
export TNS_ADMIN=/orasw/static/oradba/bin/rman/
connect rcvcat /@trmanp1
RMAN> set dbid 1523174064
RMAN> LIST BACKUP SUMMARY;
RMAN> DELETE BACKUP NOPROMPT;
RMAN> UNREGISTER DATABASE;
=========================================================================================================================================
--ACCESS FED TMO DATABASES:
sudo -u oracle /orasw/static/oradba/sysoper/bin/sysopermenu.sh pratp11
=========================================================================================================================================
--ACCESS FED TMO DATABASES II:
export ORACLE_HOME=/orasw/app/oracle/product/19/db
export PATH=$PATH:$ORACLE_HOME/bin:/usr/local/bin
. oraenv
sqlplus ROLIVEI4/"a97U5Yc38zTAHd_DQZ#p6!GxrLtkhB"
sqlplus ROLIVEI4/"reEHheGG_Gn55fb_HWasVPlnYNouMO"

sqlplus ROLIVEI4/"pcN2daWR_Bk89kq_QQrgZGjcZKaeDW"

sqlplus ROLIVEI4/"D6Ak2ehfS#HUFR_NJcBWuCZxwgm4YV"

sqlplus ROLIVEI4/"qVXI#I291bq9QF47Gyz4sQi!cMHlah"
=========================================================================================================================================
--SET OEM AGENT HOME TO CHECK STATUS:
--ORACLE_HOME=$AGENT_HOME
export ORACLE_HOME=/db01/static/app/oracle/agent13c/agent_13.4.0.0.0/
export ORACLE_HOME=/orasw/static/app/oracle/agent13c/agent_13.5.0.0.0/
export PATH=$ORACLE_HOME/bin:$PATH
emctl status agent
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
srvctl start instance -d ptesp -i ptesp2

srvctl stop listener -l LISTENER_PJPYP -n ppolabpms00001
srvctl start listener -l LISTENER_PSOCRP -n ppolabpms00001
=========================================================================================================================================
--Stop/Start Databases SYSOPER:
sudo -u root /orasw/app/19/grid/bin/crsctl stop crs

sudo -u oracle /orasw/app/19/grid/bin/srvctl stop database -d <db>
=========================================================================================================================================
--CHECK INSTANCE STATUS:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
COL INST FOR 9999
COL HOST_NAME FOR A20
SELECT INST_ID AS INST,INSTANCE_NAME,HOST_NAME,VERSION_FULL AS "VERSION",STARTUP_TIME,SYSDATE AS "CURRENT_DATE",STATUS,ARCHIVER,LOGINS,SHUTDOWN_PENDING,DATABASE_STATUS,INSTANCE_ROLE,ACTIVE_STATE,INSTANCE_MODE FROM GV$INSTANCE ORDER BY 1;
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
--ENABLE/DISABLE NPE HUNGDB
--DISABLE
/nfs/infra/oracle/scripts/maintenance/disable_npe_hungdb.sh

-- ENABLE
/nfs/infra/oracle/scripts/maintenance/enable_npe_hungdb.sh
=========================================================================================================================================
--CHECK MRP STATUS
SELECT STATUS FROM V$MANAGED_STANDBY WHERE PROCESS='MRP0';
=========================================================================================================================================
. oraenv (+ASMx)
 
srvctl stop asm -f
sudo crsctl stop has
 
srvctl start asm -f
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
FROM(SELECT (SELECT SUM(BYTES/(1014*1024*1024)) FROM DBA_DATA_FILES) "RESERVED_SPACE(GB)",
 (SELECT SUM(BYTES/(1024*1024*1024)) FROM DBA_FREE_SPACE) "FREE_SPACE(GB)" FROM DUAL);
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
=========================================================================================================================================
--CHECK TABLE PARTITIONS:
select owner,object_name,subobject_name,to_char(created,'DD.MM.YYYY HH24:MI:SS') from dba_objects where object_type='TABLE PARTITION' and trunc(created) = trunc(sysdate);
select owner,object_name,subobject_name,to_char(created,'DD.MM.YYYY HH24:MI:SS') from dba_objects where object_type='TABLE PARTITION' and owner not in ('SYS', 'AUDSYS','OPS$ORACLE','SYSTEM');
=========================================================================================================================================
-- DB SPACE BY SCHEMAS
clear columns
 column file_name format a60
 column tablespace format a30
 column total_gb format 999,999,999.99
 column used_gb format 999,999,999,999.99
 column free_gb format 999,999,999.99
 column pct_used format 999.99
 column graph format a25 heading "GRAPH (X=5%)"
 column status format a10
 compute sum of total_gb on report
 compute sum of used_gb on report
 compute sum of free_gb on report
 break on report 
 set lines 200 pages 100
 select /*+ parallel(ddf,16) parallel(dfs,16) */  total.ts tablespace,
   DECODE(total.gb,null,'OFFLINE',dbat.status) status,
  total.gb total_gb,
  NVL(total.gb - free.gb,total.gb) used_gb,
  NVL(free.gb,0) free_gb,
   DECODE(total.gb,NULL,0,NVL(ROUND((total.gb - free.gb)/(total.gb)*100,2),100)) pct_used,
  CASE WHEN (total.gb IS NULL) THEN '['||RPAD(LPAD('OFFLINE',13,'-'),20,'-')||']'
  ELSE '['|| DECODE(free.gb,
         null,'XXXXXXXXXXXXXXXXXXXX',
         NVL(RPAD(LPAD('X',trunc((100-ROUND( (free.gb)/(total.gb) * 100, 2))/5),'X'),20,'-'),
   '--------------------'))||']' 
    END as GRAPH
 from
  (select tablespace_name ts, sum(bytes)/1024/1024/1024 gb from dba_data_files ddf group by tablespace_name) total,
  (select tablespace_name ts, sum(bytes)/1024/1024/1024 gb from dba_free_space dfs group by tablespace_name) free,
   dba_tablespaces dbat
 where total.ts=free.ts(+) and
    total.ts=dbat.tablespace_name
    --and tablespace_name in ('NOR_DATA_SSD','NOR_DATA_SSD_02','NOR_INDX_SSD','NOR_DATA_SSD_TMP','APS_DATA','UNDOTBS1','UNDOTBS2','UNDOTBS3','UNDOTBS01','UNDOTBS02','UNDOTBS03','SDG_DATA')
    --and tablespace_name in ('NOR_DATA_P03','NOR_DATA_P04','NOR_DATA_P10','NOR_DATA_P11','NOR_INDX_01','REGADM_DATA')
    --and tablespace_name like ('OEMADM_DATA')
 UNION ALL
 select /*+ parallel(sh,16) */ sh.tablespace_name, 
   'TEMP',
  SUM(sh.bytes_used+sh.bytes_free)/1024/1024/1024 total_gb,
  SUM(sh.bytes_used)/1024/1024/1024 used_gb,
  SUM(sh.bytes_free)/1024/1024/1024 free_gb,
   ROUND(SUM(sh.bytes_used)/SUM(sh.bytes_used+sh.bytes_free)*100,2) pct_used,
   '['||DECODE(SUM(sh.bytes_free),0,'XXXXXXXXXXXXXXXXXXXX',
      NVL(RPAD(LPAD('X',(TRUNC(ROUND((SUM(sh.bytes_used)/SUM(sh.bytes_used+sh.bytes_free))*100,2)/5)),'X'),20,'-'),
     '--------------------'))||']'
 FROM v$temp_space_header sh
 GROUP BY tablespace_name
 order by 7 
 /
 ttitle off
 rem clear columns