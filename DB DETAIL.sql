@@ -0,0 +1,570 @@
-- CHECK ORACLE OPTIONS INSTALLED =)
select * from all_registry_banners;

--my session sid
col mysid format a20
select sys_context('USERENV','SID') as mysid from dual;

--
select s.prev_sql_id, sql.Plan_hash_value, sql.sql_fulltext from v$session s, v$sqlarea sql where sid=89 and s.prev_sql_id = sql.sql_id;

--sessÕes
col machine format a30
col sid format a5
col sid format 9999
col spid format 99999
col spid format a6
col username format a12
col osuser format a15
col machine format a20
col program format a20
col module format a20 
column wait_class format a30
 SELECT s.sid,s.serial#,P.SPID,s.username,s.osuser,s.machine,s.status,p.program,s.module,s.action,s.sql_id,s.wait_class,S.SECONDS_IN_WAIT,SW.EVENT, SW.STATE 
FROM GV$SESSION_WAIT SW, GV$SESSION S, GV$PROCESS P
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND P.ADDR=S.PADDR
AND S.USERNAME IS NOT NULL
--AND S.USERNAME IN ('TEKNISA')
--and S.OSUSER ='nagios'
--AND STATUS='KILLED'
--AND S.SID in (404)
--and inst_id=1
--and serial#=25493
--and P.PID=16392
 order by status desc;

 -- SESSÕES COM PROCESSO (PID) DO SO
 col wait_class format a30
col machine format a20
col username format a20
col program format a20
col osuser format a30
col os_commando format a20
col sopid format a10
/*select 
  s.sid,s.serial#,s.username,s.machine,s.osuser,s.status,s.program,s.sql_id,s.wait_class,
  s.BLOCKING_SESSION,s.FINAL_BLOCKING_SESSION,s.WAIT_TIME_MICRO/1000000 as wait_seconds,
  proc.spid as OS_PROC_BLOCKING, 'kill -9 '||proc.spid as OS_COMMAND
from gv$session s, gv$process proc
where s.paddr = proc.addr (+)
  and s.status='KILLED'
order by 3;*/

select 
  s.sid as sespid,proc.pid as orasid, proc.spid as sopid,s.serial#,s.username,s.machine,s.osuser,s.status,s.program,s.sql_id,s.wait_class,
  s.BLOCKING_SESSION,s.FINAL_BLOCKING_SESSION,s.WAIT_TIME_MICRO/1000000 as wait_seconds,
  proc.spid as OS_PROC_BLOCKING, 'kill -9 '||proc.spid as OS_COMMAND
from gv$session s, gv$process proc
where s.sid = proc.pid (+)
  and s.status='KILLED'
order by 3;

select 'alter system kill session '''||sid||','||serial#||''';' from v$session where osuser='nagios';

-- TABLESPACE SIZES
  SELECT TABLESPACE_NAME, (TAMANHO_TOTAL || ' MB') TAMANHO_TOTAL, (ESPACO_LIVRE ||' MB') ESPACO_LIVRE, 
        (TAMANHO_TOTAL - ESPACO_LIVRE || ' MB') OCUPADO
    FROM (SELECT A.TABLESPACE_NAME, SUM(A.BYTES)/1024/1024 TAMANHO_TOTAL, (SELECT SUM(C.BYTES)/1024/1024
                      FROM DBA_FREE_SPACE C
                     WHERE C.TABLESPACE_NAME =
                           A.TABLESPACE_NAME
                     GROUP BY C.TABLESPACE_NAME) ESPACO_LIVRE
             FROM DBA_DATA_FILES A
            GROUP BY A.TABLESPACE_NAME)
   ORDER BY TABLESPACE_NAME;

-- CONTROLFILE
SELECT *
  FROM V$CONTROLFILE;

-- OBJETOS POR USUÁRIO
SELECT OWNER, COUNT(OWNER)
  FROM DBA_OBJECTS
 WHERE OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN','DBSNMP','OLAPSYS','EXFSYS','WMSYS','CTXSYS',
  'APEX_030200','MDSYS','ORDSYS','ORACLE_OCM','XDB','OWBSYS','OWBSYS_AUDIT','OUTLN','APPQOSSYS')
 GROUP BY OWNER;

-- OBJETOS POR USUÁRIO/TIPO DE OBJETO
SELECT OWNER, OBJECT_TYPE, COUNT(OWNER)
  FROM DBA_OBJECTS
 WHERE OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN','DBSNMP','OLAPSYS','EXFSYS','WMSYS','CTXSYS',
  'APEX_030200','MDSYS','ORDSYS','ORACLE_OCM','XDB','OWBSYS','OWBSYS_AUDIT','OUTLN','APPQOSSYS')
 GROUP BY OWNER, OBJECT_TYPE
 ORDER BY 1, 2;

-- TABLESPACES, DATAFILES e TEMPFILES
  set lines 200;
  col file_name format a70;
  col tablespace_name format a25;
  col TAM format a12;
  SELECT TS.TABLESPACE_NAME,'N' AS TEMPORARY ,DF.FILE_ID,DF.FILE_NAME, TO_CHAR(ROUND(DF.BYTES / 1024 / 1024,2)) || ' MB' AS TAM, DF.AUTOEXTENSIBLE, ROUND(DF.MAXBYTES/1024/1024,2) MAXIMO, DF.INCREMENT_BY, DF.STATUS
  FROM DBA_DATA_FILES DF, DBA_TABLESPACES TS WHERE TS.TABLESPACE_NAME=DF.TABLESPACE_NAME
  --AND TS.TABLESPACE_NAME IN ('DADOS','INDICES')
  UNION ALL
  SELECT TF.TABLESPACE_NAME, 'Y' AS TEMPORARY,TF.FILE_ID,TF.FILE_NAME, TO_CHAR(ROUND(TF.BYTES / 1024 / 1024,2)) || ' MB' AS TAM, TF.AUTOEXTENSIBLE, ROUND(TF.MAXBYTES/1024/1024,2) MAXIMO, TF.INCREMENT_BY, TF.STATUS
  FROM DBA_TEMP_FILES TF
  ORDER BY 1,3;

-- TEMPFILES
col file_name format a80;
col talespace_name format a40;
col TAM format a12;
SELECT TABLESPACE_NAME, FILE_NAME, TO_CHAR(BYTES / 1024 / 1024) || ' MB' AS TAM, AUTOEXTENSIBLE, MAXBYTES/1024/1024 MAXIMO, INCREMENT_BY
  FROM DBA_TEMP_FILES
 ORDER BY 1;

--RAC TEMPFILES
col name format a60
col tablespace_name format a20
SELECT TSH.INST_ID, TSH.TABLESPACE_NAME, TSH.FILE_ID, TF.NAME, TF.BYTES/1024/1024 MB, TF.STATUS, TF.ENABLED
FROM  GV$TEMP_SPACE_HEADER TSH, GV$TEMPFILE TF 
WHERE TF.FILE#=TSH.FILE_ID
AND TF.INST_ID=TSH.INST_ID
UNION ALL
SELECT null,null,null,'TOTAL: ',SUM(TF.BYTES)/1024/1024/2,null,null
FROM GV$TEMP_SPACE_HEADER TSH, GV$TEMPFILE TF 
WHERE TF.FILE#=TSH.FILE_ID
AND TF.INST_ID=TSH.INST_ID
ORDER BY 1,2,3;

-- SCHEDULER JOBS
col repeat_interval format a40;
col job_action format a30;
col job_name format a30
col program_name format a20;
col next_run_date format a50;
col start_date format a50;
col last_start_date format a50;
col last_run_duration format a40;
col owner format a15;
col end_date format a20;
col job_action format a100;
select owner, JOB_NAME, PROGRAM_NAME, INSTANCE_ID, --10g
JOB_TYPE,START_DATE,REPEAT_INTERVAL,END_DATE,ENABLED,STATE,RUN_COUNT,FAILURE_COUNT,LAST_START_DATE,LAST_RUN_DURATION,NEXT_RUN_DATE,JOB_ACTION
from dba_scheduler_jobs
WHERE ENABLED='TRUE';
--and job_name='JOB_COLETA_ESTATISTICAS';

-- disable schedule  job
begin
dbms_scheduler.disable('WIS50HML.JB_CAMINHAO');
end;
/

-- DBA JOBS
col log_user format a20
col priv_user format a20
col schema_user format a20
col interval format a50
col what format a80
select JOB,LOG_USER,PRIV_USER,SCHEMA_USER,LAST_DATE,LAST_SEC,NEXT_DATE,NEXT_SEC,TOTAL_TIME,BROKEN,INTERVAL,WHAT 
from dba_jobs order by next_date desc, next_sec desc;


-- JOBS BROKEN (BOM PARA VERIFICAR JOBS DE VIEWS QUEBRADOS)
set lines 200
set pagesize 40
col LOG_USER format a15
col priv_user format a15
col schema_user format a15
col interval format a20
col what format a60
SELECT JOB, SCHEMA_USER, LAST_DATE, LAST_SEC, NEXT_DATE, NEXT_SEC, TOTAL_TIME, BROKEN, INTERVAL, FAILURES FAILS, WHAT, INSTANCE FROM USER_JOBS WHERE BROKEN='Y';

--SCHEDULER_LOGS
set lines 200
col log_date format a50;
col owner format a20;
col job_name format a30;
col operation format a15;
col status format a20;
select log_id, log_date, owner, job_name, operation, status from DBA_SCHEDULER_JOB_LOG where LOG_DATE > SYSDATE-5 AND job_name='JOB_COLETA_ESTATISTICAS' order by log_date;



-- OBJETOS INVÁLIDOS
SELECT COUNT(*) INVALIDOS
  FROM DBA_OBJECTS
 WHERE STATUS = 'INVALID';
 
 -- OBJETOS INVÁLIDOS POR TIPO DE OBJETO
SELECT OWNER,OBJECT_TYPE, COUNT(*) INVALIDOS
  FROM DBA_OBJECTS
 WHERE STATUS = 'INVALID' GROUP BY OWNER,OBJECT_TYPE;
 
-- REDO LOGFILE
SELECT V$LOG.GROUP#, V$LOGFILE.MEMBER, TO_CHAR(V$LOG.BYTES / 1024 / 1024) || ' MB' AS TAM, V$LOG.MEMBERS
  FROM V$LOG, V$LOGFILE
 WHERE V$LOG.GROUP# = V$LOGFILE.GROUP#
 ORDER BY 1, 2;

-- NOLOGGING OPERATIONS
set lines 200
set pagesize 50
set dbf_name format a50
set ts_name format a20
select  d.NAME as DBF_NAME, t.NAME as TS_NAME, d.UNRECOVERABLE_CHANGE# as NOLOG_CHNG#,
to_char(d.UNRECOVERABLE_TIME, 'Dy DD-Mon-YYYY HH24:MI:SS') as NOLOG_TIME
from V$DATAFILE d join V$TABLESPACE t
on d.TS# = t.TS#
order by t.NAME;
 
--ARCHIVED LOGS
 --lista
select thread#,recid, SEQUENCE#, STANDBY_DEST, stamp, name, FIRST_TIME, COMPLETION_TIME
from gv$archived_log where first_time > TO_DATE('16/07/2015', 'DD/MM/YYYY') order by COMPLETION_TIME;

--lista de hoje com tamanhos
alter session set nls_date_format='DD/MM/YYYY HH24:MI';
select thread#,sequence#, first_time,blocks*block_size/1024/1024 MB from v$archived_log  where first_time >= trunc(sysdate) order by 1,2;

 --quantidade por mês/dia
select THREAD#,trunc(first_time), count(*) from v$log_history group by THREAD#,trunc(first_time) order by 2,1,3;

--quantidade por mês/dia com tamanho total
select THREAD#,trunc(first_time), sum(blocks*block_size)/1024/1024 as MB_GENERATED from v$archived_log group by THREAD#,trunc(first_time) order by 1,2,3;


--select THREAD#,trunc(first_time), count(*) from v$log_history where first_time>SYSDATE-10 group by THREAD#,trunc(first_time) order by 2,1,3;

 --quantidade por dia/hora
select THREAD#,TO_CHAR(first_time,'MM/DD/YYYY hh24')||':00' INTERVALO, count(*) from v$log_history 
where trunc(first_time)=TO_DATE('28/08/2017','DD/MM/YYYY')
group by THREAD#,TO_CHAR(first_time,'MM/DD/YYYY hh24')
order by 1,2,3;

--GERAÇÃO DE REDO LOG POR SESSÃO
--obs: The V$SESSTAT view shows cumulative session wide statistics since the beginning of each session
col sid_serial format a15
col machine format a30
col osuser format a15
select b.inst_id, lpad((b.SID || ',' || lpad(b.serial#,5)),11) sid_serial, b.username, machine, b.osuser, b.status, a.redo_mb 
from (select n.inst_id, sid, round(value/1024/1024) redo_mb
        from gv$statname n, gv$sesstat s
        where n.inst_id=s.inst_id
              and n.name = 'redo size'
              and s.statistic# = n.statistic#
        order by value desc
     ) a, gv$session b
where b.inst_id=a.inst_id
  and a.sid = b.sid
and   rownum <= 30
order by redo_mb;

--AUDITORIA

set lines 200 pagesize 40
col ntimestamp# format a25
col hora_servidor format a27
col userid format a10
col userhost format a20
col obj$name format a20
col obj$creator format a15
select aud.sessionid, aud.entryid, aud.statement,scn_to_timestamp(aud.scn) hora_servidor, /*aud.ntimestamp#,*/aud.userid,aud.userhost,act.name,aud.returncode, aud.obj$creator, aud.obj$name
from sys.aud$ aud join sys.audit_actions act on aud.action#=act.action
where act.action not in (100,101,102)
order by hora_servidor; 
--exclui LOGON e LOGOFF

--NUMERO DE LOGONS POR HORA
col os_username format a20
col userhost format a30
select username, userhost,  to_char(timestamp,'mm/dd/yyyy hh24')||'h' logon_time,  count(*)
from dba_audit_session
where username='RADIUS'
and action_name='LOGON'
and timestamp > TO_DATE('24-JUL-14 00:00','DD-MON-RR HH24:MI')
group by username, userhost,  to_char(timestamp,'mm/dd/yyyy hh24')
order by logon_time;

--ALTERAÇÃO DE BLOCOS POR INTERVALO DE TEMPO
SELECT dhso.object_name,
sum(db_block_changes_delta)
FROM dba_hist_seg_stat dhss,
dba_hist_seg_stat_obj dhso,dba_hist_snapshot dhs
WHERE dhs.snap_id = dhss.snap_id
AND dhs.instance_number = dhss.instance_number
AND dhss.obj# = dhso.obj#
AND dhss.dataobj# = dhso.dataobj#
AND begin_interval_time BETWEEN to_date('2018/04/16 00:00','YYYY/MM/DD HH24:MI') AND to_date('2018/04/16 05:00','YYYY/MM/DD HH24:MI')
GROUP BY dhso.object_name
order by sum(db_block_changes_delta);

--QUEM ESTÁ ALTERANDO MAIS REDO ATUALMENTE?
set lines 200 pagesize 50
 SELECT  s.inst_id ,s.sid, s.serial#, s.username, s.program, i.block_changes
FROM gv$session s, gv$sess_io i
WHERE s.sid = i.sid AND i.block_changes > 1000
ORDER BY 6 DESC, 1,2;

/*
SELECT dhso.object_name,
sum(db_block_changes_delta)
FROM dba_hist_seg_stat dhss,
v$tablespace tbs,
dba_hist_seg_stat_obj dhso,
dba_hist_snapshot dhs
WHERE dhs.snap_id = dhss.snap_id
AND tbs.TS# = dhss.TS#
AND tbs.NAME='TASY_DATA'
AND dhs.instance_number = dhss.instance_number
AND dhss.obj# = dhso.obj#
AND dhss.dataobj# = dhso.dataobj#
AND begin_interval_time BETWEEN to_date('2013/05/13 00:00','YYYY/MM/DD HH24:MI') AND to_date('2013/05/13 23:59','YYYY/MM/DD HH24:MI')
GROUP BY dhso.object_name
order by sum(db_block_changes_delta);
*/

--PEGAR SQLs QUE GERARAM ESSA ALTERAÇÃO:
SELECT distinct dbms_lob.substr(sql_text,4000,1)
FROM dba_hist_sqlstat dhss,
dba_hist_snapshot dhs,
dba_hist_sqltext dhst
WHERE upper(dhst.sql_text) LIKE '%TB_MOEDA%'
AND dhss.snap_id=dhs.snap_id
AND dhss.instance_Number=dhs.instance_number
AND dhss.sql_id = dhst.sql_id and rownum<2;

--OCUPAÇÃO DA SYSAUXl
set linesize 120
set pagesize 100
COLUMN "Item" FORMAT A25
COLUMN "Space Used (GB)" FORMAT 999.99
COLUMN "Schema" FORMAT A25
COLUMN "Move Procedure" FORMAT A40
SELECT  occupant_name "Item",
    space_usage_kbytes/1048576 "Space Used (GB)",
    schema_name "Schema",
    move_procedure "Move Procedure"
FROM v$sysaux_occupants
ORDER BY 1
/

--VERIFICAR O ULTIMO REFRESH DA MATERIALIZED VIEW
SELECT owner, mview_name, last_refresh_date
  FROM all_mviews
 WHERE owner = <<user that owns the materialized view>>
   AND mview_name = <<name of the materialized view>>
 
--VERIFICAR USO DA TEMP (TEMP USAGE)
/*NOTA: v$tempfile mostra os tempfiles de todas instâncias, repetindo o mesmo tempfile para cada uma */
/*SELECT A.tablespace_name tablespace, D.mb_total,
SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM v$sort_segment A,
(
SELECT B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
FROM v$tablespace B, v$tempfile C
WHERE B.ts#= C.ts#
GROUP BY B.name, C.block_size
) D
WHERE A.tablespace_name = D.name
GROUP by A.tablespace_name, D.mb_total;*/

--VERIFICAR USO DA TEMP (TEMP USAGE) - MAIS SIMPLES
col TABLESPACE_SIZE format a30
col ALLOCATED_SPACE format a30
col FREE_SPACE format a30
select tablespace_name, 
  TABLESPACE_SIZE/1024/1024|| ' MB' TABLESPACE_SIZE,
  ALLOCATED_SPACE/1024/1024|| ' MB' ALLOCATED_SPACE,
  FREE_SPACE/1024/1024|| ' MB' FREE_SPACE from dba_temp_free_space;

--TEMP USAGE BY SESSION AND BLOCKS (WHERE BLOCKS USAGE > 128)

set lines 200 pagesize 80
col hash_value format a50
col tablespace format a15
col username format a20
SELECT s.inst_id, s.sid, s.username, u.tablespace, s.SQL_ID,u.sqlhash, u.segtype, u.contents, u.blocks
FROM gv$session s, gv$tempseg_usage u
WHERE s.saddr=u.session_addr
and u.blocks > 128
order by u.blocks;

 -- VERIFICAÇÃO DE USO DA UNDO (UNEXPIRED/EXPIRED EXTENTS)
select tablespace_name, status, sum(blocks) * 8192/1024/1024/1024 GB from dba_undo_extents group by tablespace_name, status;

-- UTILIZAÇÃO DE UNDO POR TRANSAÇÃO ATIVA
select s.sid,s.serial#,s.username,s.machine,sq.sql_text sql_text, t.USED_UREC Records, t.USED_UBLK Blocks, (t.USED_UBLK*8192/1024) KBytes
from v$transaction t, v$session s, v$sql sq
where t.addr = s.taddr
and s.sql_id = sq.sql_id
and s.sid=82;
--and s.username = '<user>'
/
 
 -- TAMANHO DE SEGMENTO POR TABLESPACE
col segment_name format a30
SELECT OWNER, TABLESPACE_NAME, SEGMENT_NAME, SEGMENT_TYPE, BYTES/1024/1024 MB, EXTENTS 
FROM DBA_SEGMENTS WHERE TABLESPACE_NAME='TADADOS' AND BYTES > 536870912 ORDER BY 5;

--ANÁLISE DE SGA COM GERENCIAMENTO AUTOMÁTICO

SELECT * FROM V$SGA_DYNAMIC_COMPONENTS;

--USO DA FLASHBACK RECOVERY AREA

SELECT * FROM V$FLASH_RECOVERY_AREA_USAGE;



--VERIFICACAO DE OPERACOES DEMORADAS
HIST_

--ÚLTIMA HORA
col "ELAPSED(s)" format a10
col units format a10
col message format a80
col target format a20
alter session set nls_date_format='DD/MM/YYYY HH24:MI';
select USERNAME,SID,SERIAL#,START_TIME,ELAPSED_SECONDS||'s' "ELAPSED(s)",UNITS,SOFAR,TOTALWORK,TIME_REMAINING,TARGET,LAST_UPDATE_TIME,SQL_ID,OPNAME,MESSAGE
from gv$session_longops
WHERE 
--start_time > SYSDATE-1/24 --ultima hora
start_time > SYSDATE-7 --ultimos 7 dias
--and sid=126
order by start_time;

--OPERACOES LONGAS AINDA ATIVAS
col target format a18
col opname format a30
col units format a10
col message format a100
col "ELAPSED(s)" format a10
alter session set nls_date_format='DD/MM/YYYY HH24:MI';
select USERNAME,SID,SERIAL#,START_TIME,ELAPSED_SECONDS||'s' "ELAPSED(s)",UNITS,SOFAR,TOTALWORK,TIME_REMAINING,TARGET,LAST_UPDATE_TIME,SQL_ID,OPNAME,MESSAGE
from gv$session_longops
WHERE SOFAR <> TOTALWORK
order by start_time;
/*
WHERE SID=1891
order by start_time;
*/

--PEGAR O SQL DA SESSÃO
SELECT SQL_TEXT from v$SQLAREA WHERE SQL_ID='5nhnaccjuwaf9';

--PEGAR SQL EXPLAIN PLAN - PLANO DE EXECUCAO (VERIFICAR SE PODE)
--select *
--from table(dbms_xplan.display_cursor(sql_id => '7v200k15svxmg', format => '+ALLSTATS'));

--PEGAR BINDS (estudar)

--VERIFICAR LOCKS
col blocking_session format a6
col sid format a6
col serial# format a8
col inst_id format a10
col module format a30	
col event format a40
select SADDR ,to_char( inst_id ) inst_id, to_char( sid ) sid, to_char( serial# ) serial#, module, event, to_char( blocking_session ) blocking_session
from gv$session where blocking_session is not  null;

--select SID,SERIAL#,STATUS,USERNAME,OSUSER,PROCESS,MACHINE,TERMINAL,PROGRAM,SQL_ID,SQL_ADDRESS,STATE,WAIT_CLASS,BLOCKING_SESSION,EVENT from v$session where sid=4009;

--VERIFICAR ESPERA DE DATAPUMP
SELECT   w.sid, w.event, w.seconds_in_wait
FROM   V$SESSION s, DBA_DATAPUMP_SESSIONS d, V$SESSION_WAIT w
WHERE   s.saddr = d.saddr AND s.sid = w.sid;

--Verificar library cache lock em view oculta
select * from x$kgllk where KGLLKSES = 'saddr' and KGLLKREQ>0;

-- VERIFICAÇÃO DE BACKUPS RMAN
set pages 2000 lines 200
COL STATUS FORMAT a9
COL hrs FORMAT 999.99
select INPUT_TYPE, STATUS, TO_CHAR(START_TIME,'mm/dd/yy hh24:mi') start_time, TO_CHAR(END_TIME,'mm/dd/yy hh24:mi') end_time,ELAPSED_SECONDS/3600 hrs, 
INPUT_BYTES/1024/1024/1024 SUM_BYTES_BACKED_IN_GB, OUTPUT_BYTES/1024/1024/1024 SUM_BACKUP_PIECES_IN_GB,OUTPUT_DEVICE_TYPE
FROM V$RMAN_BACKUP_JOB_DETAILS
order by SESSION_KEY;


-- VERIFICAÇÃO DE BLOCOS CORROMPIDOS DETECTADOS EM ÚLTIMO RMAN

col objeto format a50
col name format a80
SELECT EXT.OWNER||'.'||EXT.SEGMENT_NAME OBJETO, EXT.SEGMENT_TYPE, DBCORRUP.BLOCKS, DBCORRUP.BLOCK#, DBF.NAME
FROM DBA_EXTENTS EXT, V$DATABASE_BLOCK_CORRUPTION DBCORRUP, V$DATAFILE DBF
WHERE EXT.FILE_ID=DBCORRUP.FILE#
AND EXT.FILE_ID=DBF.FILE#
AND DBCORRUP.BLOCK# BETWEEN EXT.BLOCK_ID AND EXT.BLOCK_ID+EXT.BLOCKS -1;


-- PEGAR GRANTs DDLS de ROLEs

SELECT dbms_metadata.get_ddl('ROLE', role) FROM dba_roles;
SELECT dbms_metadata.get_granted_ddl('ROLE_GRANT',  'RL_SIGACRED') FROM dual;
SELECT dbms_metadata.get_granted_ddl('SYSTEM_GRANT','RL_SIGACRED') FROM dual;
SELECT dbms_metadata.get_granted_ddl('OBJECT_GRANT','RL_SIGACRED') FROM dual;


---VERIFICACAO DE ENDIAN FORMATS
select * from v$transportable_platform order by platform_id;

-----------------------
---DATAGUARD
-----------------------

--SOBRE ROLE DA BASE

SELECT PROTECTION_MODE, PROTECTION_LEVEL,DATABASE_ROLE ROLE, SWITCHOVER_STATUS
FROM V$DATABASE;

--FAILOVER INFO

SELECT FS_FAILOVER_STATUS "FSFO STATUS",FS_FAILOVER_CURRENT_TARGET TARGET,FS_FAILOVER_THRESHOLD THRESHOLD,FS_FAILOVER_OBSERVER_PRESENT "OBSERVER PRESENT"
FROM V$DATABASE;

--STATUS DO REDO APPLY
SELECT PROCESS, STATUS, THREAD#, SEQUENCE#, BLOCK#, BLOCKS FROM V$MANAGED_STANDBY;

--MENSAGENS DE ALERTA
SELECT MESSAGE FROM V$DATAGUARD_STATUS;

--STANDBY REDOS
select * from v$standby_log;

--ARCHIVES LOG DESTS
select * from gv$archive_dest where status='VALID';

--CONFIGURAÇÃO DO BROKER
show parameter broker;

--LISTAGEM GERAL DOS ARCHIVES NO PRIMARIO COM DIVERSAS INFORMACOES
set lines 200
set pagesize 40
col name format a60
col applied format a7
select dest_id, thread#, sequence# seq, resetlogs_id, creator, registrar, standby_dest, backup_count bkp_count, archived, applied, name from v$archived_log;

--ESTADO DOS REDOS/ARCHIVES PELA SEQUENCE E THREAD
 SELECT (SELECT name FROM V$DATABASE) name, (SELECT MAX (sequence#) FROM v$archived_log WHERE dest_id = 1) Current_primary_seq,
  (SELECT MAX (sequence#)
    FROM v$archived_log
    WHERE TRUNC(next_time) > SYSDATE - 1
    AND dest_id = 2
  ) max_stby,
  (SELECT NVL ((SELECT MAX (sequence#) - MIN (sequence#)
      FROM v$archived_log
      WHERE TRUNC(next_time) > SYSDATE - 1
      AND dest_id = 2
      AND applied = 'NO'
      ), 0)
  FROM DUAL
  ) "To be applied",
  ((SELECT MAX (sequence#) FROM v$archived_log WHERE dest_id = 1) -(SELECT MAX (sequence#) FROM v$archived_log WHERE dest_id = 2
  )) "To be Shipped"
FROM DUAL;

SELECT DESTINATION, STATUS, ARCHIVED_THREAD#, ARCHIVED_SEQ#
FROM V$ARCHIVE_DEST_STATUS
WHERE STATUS <> 'DEFERRED' AND STATUS <> 'INACTIVE';

--VERIFICAR SE EXISTE GAP DE ARCHIVES
SELECT LOCAL.THREAD#, LOCAL.SEQUENCE# 
FROM (SELECT THREAD#, SEQUENCE# FROM V$ARCHIVED_LOG WHERE DEST_ID=1) LOCAL 
WHERE LOCAL.SEQUENCE# 
NOT IN (SELECT SEQUENCE# FROM V$ARCHIVED_LOG WHERE DEST_ID=2 AND THREAD# = LOCAL.THREAD#);