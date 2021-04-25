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
and S.OSUSER ='Rafael T.I'
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
select owner, JOB_NAME, PROGRAM_NAME--, INSTANCE_ID, --10g
JOB_TYPE,START_DATE,REPEAT_INTERVAL,END_DATE,ENABLED,STATE,RUN_COUNT,FAILURE_COUNT,LAST_START_DATE,LAST_RUN_DURATION,NEXT_RUN_DATE,JOB_ACTION
from dba_scheduler_jobs
WHERE ENABLED='TRUE'
and job_name like '%envia%';

-- SCHEDULER JOB HISTORY/LOG
col log_date format a50
col job_name format a40
col run_duration format a50
select log_date,job_name,status,run_duration
from dba_scheduler_job_run_details
where job_name='FOCCOMAIL_PCP006_SUBST_DEMAN'
order by log_date;

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

--select JOB,LOG_USER,PRIV_USER,SCHEMA_USER,LAST_DATE,LAST_SEC,NEXT_DATE,NEXT_SEC,TOTAL_TIME,BROKEN,INTERVAL,WHAT from dba_jobs where trunc(last_date)>SYSDATE order by next_date desc, next_sec desc;

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


-- NETWORK ACL
 select * from dba_network_acls;
 select * from dba_network_acl_privileges;
 
-- Permissão adicional necessária:
--grant execute on utl_http to scott;

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
from gv$archived_log where first_time >= TO_DATE('11/10/2019', 'DD/MM/YYYY') order by COMPLETION_TIME;


--lista de hoje com tamanhos
alter session set nls_date_format='DD/MM/YYYY HH24:MI';
select thread#,sequence#, first_time,blocks*block_size/1024/1024 MB from v$archived_log  where first_time >= trunc(sysdate) order by 1,2;

 --quantidade por mês/dia
select THREAD#,trunc(first_time), count(*) from v$log_history group by THREAD#,trunc(first_time) order by 2,1,3;

--quantidade por mês/dia com tamanho total
select THREAD#,trunc(first_time),count(*), sum(blocks*block_size)/1024/1024 as MB_GENERATED from v$archived_log group by THREAD#,trunc(first_time) order by 1,2,4;

--select THREAD#,trunc(first_time), count(*) from v$log_history where first_time>SYSDATE-10 group by THREAD#,trunc(first_time) order by 2,1,3;

 --quantidade por dia/hora
select THREAD#,TO_CHAR(first_time,'MM/DD/YYYY hh24')||':00' INTERVALO, count(*) from v$log_history 
where trunc(first_time)=TO_DATE('01/10/2019','DD/MM/YYYY')
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

--PARAR DE AUDITAR LOGON/LOGOFF: NOAUDIT SESSION
-- AUDITAR DROP/CREATE TABLE: AUDIT TABLE

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

-- OPERAÇÕES RECENTES A PARTIR DO TIMESTAMP ESCOLHIDO
select username,os_username,obj_name,timestamp,action_name from dba_audit_trail where timestamp between TO_DATE('21/10/2019 16:00', 'dd/mm/yyyy hh24:mi') and  TO_DATE('21/10/2019 19:00', 'dd/mm/yyyy hh24:mi') order by timestamp;

select username,os_username,obj_name,timestamp,action_name from dba_audit_trail where timestamp > TO_DATE('31/08/2019 16:18', 'dd/mm/yyyy hh24:mi') order by timestamp;

--soma por dia, operação, obj e outros campos
select trunc(timestamp) as dia, username,os_username,obj_name,action_name,count(*) from dba_audit_trail where timestamp > TO_DATE('31/08/2019 16:18', 'dd/mm/yyyy hh24:mi') group by trunc(timestamp),username,os_username,obj_name,action_name order by 1,2,3,4,5;


--OUTROS SOBRE AUDITORIA

/* https://oracle-base.com/articles/8i/auditing

The audit trail is stored in the SYS.AUD$ table. It's contents can be viewed directly or via the following views.

DBA_AUDIT_EXISTS
DBA_AUDIT_OBJECT
DBA_AUDIT_SESSION
DBA_AUDIT_STATEMENT
DBA_AUDIT_TRAIL
DBA_OBJ_AUDIT_OPTS
DBA_PRIV_AUDIT_OPTS
DBA_STMT_AUDIT_OPTS

The audit trail contains a lot of data, but the following are most likely to be of interest.

USERNAME : Oracle Username.
TERMINAL : Machine that the user performed the action from.
TIMESTAMP : When the action occured.
OBJECT_OWNER : The owner of the object that was interacted with.
OBJECT_NAME : The name of the object that was interacted with.
ACTION_NAME : The action that occured against the object. (INSERT, UPDATE, DELETE, SELECT, EXECUTE)

*/

--tables audited
select * from dba_obj_audit_opts;

--statements audited
SELECT audit_option, success, failure FROM dba_stmt_audit_opts;

-- all operations audited in object X last "systimestamp-N"
col username format a10
col owner format a10
col os_username format a15
col userhost format a20
col terminal format a20
col obj_name format a30
col comment_text format a20
col sql_text format a50
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';
SELECT INSTANCE_NUMBER,OS_USERNAME, USERNAME, TERMINAL,TIMESTAMP,OWNER,OBJ_NAME,ACTION_NAME,
decode(ses_actions,
       '---S------------','DELETE',
       '------S---------','INSERT',
       '---------S------','SELECT',
       '----------S-----','UPDATE',
       '---S--S--S------','DELETE/INSERT/SELECT',
       '---S--S--SS-----','DELETE/INSERT/SELECT/UPDATE',
       '------S--S------','INSERT/SELECT',
       '------S--SS-----','INSERT/SELECT/UPDATE',
       '---------SS-----','SELECT/UPDATE',
       SES_ACTIONS) as DML_ACTION,
SESSIONID,ENTRYID,STATEMENTID,RETURNCODE,OS_PROCESS,TRANSACTIONID,SCN,COMMENT_TEXT,SQL_TEXT from dba_audit_object 
where obj_name='HSSESPRE' and timestamp>systimestamp-4/24 order by timestamp;
/* SES_ACTIONS: a string of 16 characters, one for each action type in the order 1 ALTER, 2 AUDIT, 3 COMMENT, 4 DELETE, 5 GRANT, 6 INDEX, 7 INSERT, 8 LOCK, 9 RENAME, 10 SELECT, 11 UPDATE, 12 REFERENCES, and 13 EXECUTE. Positions 14, 15, and 16 are reserved for future use, character:
- - None
S - Success
F - Failure
B - Both*/

--TRIGGER DE AUDIT DE DETERMINADOS USUARIOS (EXEMPLO)

/*CREATE OR REPLACE TRIGGER TRI_LOGON_USERS
AFTER LOGON ON DATABASE
DECLARE
    osUser VARCHAR2(30);
    dbuser VARCHAR(30);
    machine VARCHAR2(100); 
    prog VARCHAR2(100);
    ip_user VARCHAR2(15);
BEGIN
    SELECT OSUSER, USERNAME, MACHINE, PROGRAM, ora_client_ip_address
    INTO osUser, dbuser, machine, prog, ip_user
    FROM v$session
    WHERE SID = SYS_CONTEXT('USERENV', 'SID');

    IF (LOWER(osUser) IN ('solushosp1','solushosp2','solusops1','solusops2','prisma','bioaps')) THEN
        execute immediate 'audit insert table, update table, delete table in session current by access';
    END IF;
END;
/
*/

--all actions audited last hour
select act.action,act.name,count(*) from sys.aud$ aud, sys.audit_actions act where aud.action#=act.action and aud.ntimestamp#>systimestamp-1/24 group by act.action, act.name;

	  
--select act.action,act.name,count(*) from sys.aud$ aud, sys.audit_actions act where obj$name='HSSESPRE' and aud.action#=act.action and aud.ntimestamp#>systimestamp-1/24 group by act.action, act.name;

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
AND begin_interval_time BETWEEN to_date('2019/09/12 00:00','YYYY/MM/DD HH24:MI') AND to_date('2019/09/12 23:59','YYYY/MM/DD HH24:MI')
GROUP BY dhso.object_name
order by sum(db_block_changes_delta);

--QUEM ESTÁ ALTERANDO MAIS REDO ATUALMENTE?
--> VER "UTILIZAÇÃO DE UNDO POR TRANSAÇÃO ATIVA COM QUANTIDADE DE REDO ACUMULADO PELA SESSAO"
 

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
WHERE upper(dhst.sql_text) LIKE '%AGRFLTIC%'
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
select s.sid,s.serial#,s.username,s.machine, t.USED_UREC UNDO_Records, t.USED_UBLK UNDO_Blocks, (t.USED_UBLK*8192/1024/1024) MBytes,sq.sql_text sql_text
from v$transaction t, v$session s, v$sql sq
where t.addr = s.taddr
and s.sql_id = sq.sql_id
and (t.USED_UBLK*8192/1024/1024) > 10
order by 7
/

-- UTILIZAÇÃO DE UNDO POR TRANSAÇÃO ATIVA COM QUANTIDADE DE REDO ACUMULADO PELA SESSAO
col username format a15
select s.sid,s.serial#,s.status,s.username,s.machine, t.USED_UREC UNDO_Records, t.USED_UBLK UNDO_Blocks, 
(t.USED_UBLK*8192/1024/1024) UNDO_MBytes, r.redo_mb redo_cumulative_mb,sq.sql_id
from v$transaction t, v$session s, v$sqlarea sq, 
	(select sid, round(value/1024/1024) redo_mb
        from v$statname n, v$sesstat s
        where n.name = 'redo size'
              and s.statistic# = n.statistic#) r
where t.addr (+) = s.taddr
and s.sql_id = sq.sql_id (+)
and r.sid=s.sid
and username is not null
and r.redo_mb > 1
--and (t.USED_UBLK*8192/1024/1024) > 10
order by 3,8,9
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
-- HIST_ nao uso mais

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
select SESSION_KEY,SESSION_RECID,SESSION_STAMP,INPUT_TYPE, STATUS, TO_CHAR(START_TIME,'mm/dd/yy hh24:mi') start_time, TO_CHAR(END_TIME,'mm/dd/yy hh24:mi') end_time,ELAPSED_SECONDS/3600 hrs, 
INPUT_BYTES/1024/1024/1024 SUM_BYTES_BACKED_IN_GB, OUTPUT_BYTES/1024/1024/1024 SUM_BACKUP_PIECES_IN_GB,OUTPUT_DEVICE_TYPE
FROM V$RMAN_BACKUP_JOB_DETAILS
where start_time > sysdate-7
--where session_key=88833
order by SESSION_KEY;


select bst.session_key,bst.SESSION_STAMP,bjd.STATUS,bst.SET_COUNT,decode(bst.backup_type,'L','ArchiveLog','D','Datafile','I','Incremental') backup_type,bst.CONTROLFILE_INCLUDED,bst.INCREMENTAL_LEVEL as incr_lvl, bst.PIECES,
bst.start_time,bst.elapsed_seconds/60 as MINUTES, bst.DEVICE_TYPE,bst.COMPRESSED,bst.OUTPUT_BYTES/1024/1024 as OUTPUT_MB, 
bst.ORIGINAL_INPUT_BYTES/1024/1024 as INPUT_MB, bst.COMPRESSION_RATIO, bst.STATUS
from V$BACKUP_SET_DETAILS bst, V$RMAN_BACKUP_JOB_DETAILS bjd
where bjd.SESSION_KEY=bst.SESSION_KEY
and bjd.SESSION_RECID=bst.SESSION_RECID
and bjd.SESSION_STAMP=bst.SESSION_STAMP
--and bst.session_key=89493
--and bst.bs_key=134593
and bst.start_time > sysdate-7
order by 1,2,bst.start_time,bst.set_count;

-- RMAN OUTPUT, LAST INCR LVL 0
select output from v$rman_output ro, v$backup_set_details bsd where bsd.incremental_level=0 and start_time=(select max(start_time) from v$backup_set_details where incremental_level=0) and ro.session_key=bsd.session_key;

--- QUERY DE RMAN

set lines 220
set pages 1000
col cf for 9,999
col df for 9,999
col elapsed_seconds heading "ELAPSED|SECONDS"
col i0 for 9,999
col i1 for 9,999
col l for 9,999
col output_mbytes for 9,999,999 heading "OUTPUT|MBYTES"
col session_recid for 999999 heading "SESSION|RECID"
col session_stamp for 99999999999 heading "SESSION|STAMP"
col status for a10 trunc
col time_taken_display for a10 heading "TIME|TAKEN"
col output_instance for 9999 heading "OUT|INST"
select
  j.session_recid, j.session_stamp,
  to_char(j.start_time, 'yyyy-mm-dd hh24:mi:ss') start_time,
  to_char(j.end_time, 'yyyy-mm-dd hh24:mi:ss') end_time,
  (j.output_bytes/1024/1024) output_mbytes, j.status, j.input_type,
  decode(to_char(j.start_time, 'd'), 1, 'Sunday', 2, 'Monday',
                                     3, 'Tuesday', 4, 'Wednesday',
                                     5, 'Thursday', 6, 'Friday',
                                     7, 'Saturday') dow,
  j.elapsed_seconds, j.time_taken_display,
  x.cf, x.df, x.i0, x.i1, x.l,
  ro.inst_id output_instance
from V$RMAN_BACKUP_JOB_DETAILS j
  left outer join (select
                     d.session_recid, d.session_stamp,
                     sum(case when d.controlfile_included = 'YES' then d.pieces else 0 end) CF,
                     sum(case when d.controlfile_included = 'NO'
                               and d.backup_type||d.incremental_level = 'D' then d.pieces else 0 end) DF,
                     sum(case when d.backup_type||d.incremental_level = 'D0' then d.pieces else 0 end) I0,
                     sum(case when d.backup_type||d.incremental_level = 'I1' then d.pieces else 0 end) I1,
                     sum(case when d.backup_type = 'L' then d.pieces else 0 end) L
                   from
                     V$BACKUP_SET_DETAILS d
                     join V$BACKUP_SET s on s.set_stamp = d.set_stamp and s.set_count = d.set_count
                   where s.input_file_scan_only = 'NO'
                   group by d.session_recid, d.session_stamp) x
    on x.session_recid = j.session_recid and x.session_stamp = j.session_stamp
  left outer join (select o.session_recid, o.session_stamp, min(inst_id) inst_id
                   from GV$RMAN_OUTPUT o
                   group by o.session_recid, o.session_stamp)
    ro on ro.session_recid = j.session_recid and ro.session_stamp = j.session_stamp
where j.start_time > trunc(sysdate)-&NUMBER_OF_DAYS
order by j.start_time;
 
 
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



/*

select TO_CHAR(TIME_DP,'DD-MM-YYYY HH24:MI:SS') DATE_TIME,SCN FROM SMON_SCN_TIME order by 2;
select current_scn from v$database;