--Verificação de diversas estatísticas
SELECT * FROM V$SYSSTAT WHERE VALUE>0 ORDER BY VALUE;

--Contagem de parses:
select a.*,sysdate-b.startup_time days_old from v$sysstat a,v$instance b where a.name like 'parse%'

--Hard parse por sessão 
--!!!!! (Verificar uso do AWR) !!!!!!
select a.sid,c.username,b.name,a.value,round((sysdate-c.logon_time)*24) hours_connected from v$sesstat a, v$statname b, v$session c 
where c.sid=a.sid and a.statistic#=b.statistic# and a.value>0 and b.name ='parse count (hard)' order by a.value;

--Pegar uma determinada estatística por sessão: 
--!!!!! (Verificar uso do AWR) !!!!!!

select s.serial#,s.username,s.machine,stm.* 
from v$sess_time_model stm
left join v$session s on stm.sid=s.sid
where stm.value>0
and stm.stat_name like 'failed parse%'
order by stm.value;

--Verificar se existem objetos de usuário em tablespace de sistema (dicionário de dados)
SELECT DISTINCT OWNER, TABLESPACE_NAME FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME IN ('SYSTEM','SYSAUX') AND OWNER NOT IN ('SYS','SYSTEM','SYSMAN','DBSNMP');

--Verificação de tamanho de objetos por usuário ou tablespace
SELECT OWNER, SEGMENT_TYPE, SEGMENT_NAME, TABLESPACE_NAME, BYTES/1024/1024 "TAMANHO(MB)", EXTENTS
       FROM DBA_SEGMENTS
            WHERE TABLESPACE_NAME='SYSAUX' and BYTES > 1048576
            order by "TAMANHO(MB)";
--select * from dba_lobs where owner='PADRAO2T';

---Library Cache Hit (http://docs.oracle.com/cd/B28359_01/server.111/b28274/memory.htm)
select sum(pinhits) / sum(pins) from v$librarycache;

--Buffer Cache Hit
SELECT (P1.value + P2.value - P3.value) / (P1.value + P2.value)
     FROM   v$sysstat P1, v$sysstat P2, v$sysstat P3
     WHERE  P1.name = 'db block gets'
     AND    P2.name = 'consistent gets'
     AND    P3.name = 'physical reads';

--Verificação de número de extents por objeto
SELECT OWNER, SEGMENT_NAME, TABLESPACE_NAME, BYTES/1024/1024 TAMANHO, EXTENTS
       FROM DBA_SEGMENTS
            WHERE EXTENTS > 200 ORDER BY EXTENTS;
			
--Contagem de extents por tamanho de objeto específico:
select bytes/1024, count(*) from dba_extents where segment_name = 'NFE_RETORNO' group by bytes/1024 order by 1;

--SGA TOTAL USAGE
select round(used.bytes /1024/1024 ,2) used_mb
, round(free.bytes /1024/1024 ,2) free_mb
, round(tot.bytes /1024/1024 ,2) total_mb
from (select sum(bytes) bytes
from v$sgastat
where name != 'free memory') used
, (select sum(bytes) bytes
from v$sgastat
where name = 'free memory') free
, (select sum(bytes) bytes
from v$sgastat) tot
/

--Resizes da SGA
Col When Format A25
Col Component Format A25
Select To_Char(Start_Time, 'Mon-Dd Hh24:Mi:Ss') When ,Component, Oper_Type, Initial_Size, Final_Size
From V$Sga_Resize_Ops; 

--VERIFICACAO DE ADVICES PARA SHARED_POOL
select shared_pool_size_for_estimate "size",
 shared_pool_size_factor "factor",
 estd_lc_time_saved "result"
 from v$shared_pool_advice;
 --size tamanho da sga (1.0 no factor é o tamanho atual)
 --result é o tempo de parse no tamanho do size no registro

 --Outros advices:
 --GV$SGA_TARGET_ADVICE
 --GV$SHARED_POOL_ADVICE
 --GV$MEMORY_TARGET_ADVICE
 --

 ---CONTAGEM DE OPENED CURSORS

 --total

select max(a.value) as highest_open_cur, p.value as max_open_cur
from v$sesstat a, v$statname b, v$parameter p
 where a.statistic# = b.statistic# 
 and b.name = 'opened cursors current'
 and p.name= 'open_cursors'
 group by p.value;

 --persession

col username format a10
select a.value, s.username, s.sid, s.serial#,s.osuser,s.program from v$sesstat a, v$statname b, v$session s where a.statistic# = b.statistic#  and s.sid=a.sid and b.name = 'opened cursors current' and s.username is not null;

-- CONTAGEM DE ESTATÍSTICAS (last_analyzed) DE TABELA E INDICES POR DATA:
select distinct trunc(last_analyzed), count(*) 
from dba_tables 
where owner='FOCCO3I' group by trunc(last_analyzed) 
order by 1,2;


select distinct trunc(last_analyzed), count(*) 
from dba_indexes 
where owner='FOCCO3I' 
group by trunc(last_analyzed) order by 1,2;


-- CONTAGEM DE STALE STATISTICS/ESTATISTICAS

--tables
col TABLE_NAME for a30
col PARTITION_NAME for a20
col SUBPARTITION_NAME for a20
SELECT OWNER, COUNT(*) as STALE_TABLES
from dba_TAB_STATISTICS 
where STALE_STATS='YES' and OWNER like 'FOCCO%'
group by OWNER;
--indexes
SELECT OWNER, COUNT(*) as STALE_INDEXES
from dba_ind_STATISTICS 
where STALE_STATS='YES' and OWNER like 'FOCCO%'
group by OWNER;

--Fragmented tables

select
   table_name,round((blocks*8/1024),2) "size (mb)" ,
   round((num_rows*avg_row_len/1024/1024),2) "actual_data (mb)",
   (round((blocks*8/1024),2) - round((num_rows*avg_row_len/1024/1024),2)) "wasted_space (mb)"
from
   dba_tables
where
   (round((blocks*8),2) > round((num_rows*avg_row_len/1024),2))
   and blocks*8/1024 >= 512
   and table_name='LOGOPERA'
order by 4 desc;

--------------------------------------------------------------------------------
-- Fragmented Indexes (EM PESQUISA)

-- Analyze index .... validate structure -> preenche a INDEX_STATS, que só tem 1 linha, um novo analyze apagará a index_stats e inserirá os novos valores
-- Standard não suporta reconstrução ONLINE

-- General tips:
-- 1)     If the index has height greater than four, rebuild the index.
-- 2)     The deleted leaf rows should be less than 20%.

--Ver:
-- https://oradbaeasy.wordpress.com/2009/06/01/how-to-determine-an-index-needs-to-be-rebuilt/

--------------------------------------------------------------------------------

/*
"The Tuning Pack for databases is normally sold as a corollary to the Diagnostics Pack, because you need to diagnose problems first before you tune. 
This pack is very important for performance tuning purposes, since it offers a gold mine of tuning advisors and utilities: the SQL Tuning Advisor, 
SQL Tuning sets, SQL Access Advisor, Segment Advisor, Real-Time SQL Monitoring, and so on."*/

/*================ SEGMENT ADVISOR FINDINGS -- FUCKING ENTERPRISE =====================*/
 
 /*
SET LINESIZE 250
SET PAGESIZE 40
SET COLSEP '|'
COLUMN task_name FORMAT A20
COLUMN object_type FORMAT A12
COLUMN schema FORMAT A10
COLUMN object_name FORMAT A30
COLUMN message FORMAT A100
COLUMN more_info FORMAT A100

SELECT f.task_name,
       f.impact,
       o.type AS object_type,
       o.attr1 AS schema,
       o.attr2 AS object_name,
       f.message,
       f.more_info
FROM   dba_advisor_findings f
       JOIN dba_advisor_objects o ON f.object_id = o.object_id AND f.task_name = o.task_name
WHERE  o.attr2 like '%400'
ORDER BY f.task_name, f.impact DESC;
 */
            
 /*================VERIFICAÇÃO DE CURSORES ABERTOS POR USUÁRIO (SQLs que está executando) =====================*/
 
 select sid, serial#, username, osuser,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID, sql_address,BLOCKING_SESSION,FINAL_BLOCKING_SESSION,SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID 
 from gv$session 
 where sid=2633
 #and inst_id=1

--byoracle
 select a.value, s.username, s.sid, s.serial# from v$sesstat a
, v$statname b, v$session s where a.statistic# = b.statistic#  
and s.sid=a.sid and b.name = 'opened cursors current' and s.username is not null order by VALUE,USERNAME;
 
 select * from v$open_cursor 
 where
 SID=1106
 order by LAST_SQL_ACTIVE_TIME
 --SQL_ID = 'bxwk6ngq1pgwc'
 --and
 SID=713
 --AND SQL_TEXT LIKE '%UPDATE%'
 ;

select * from v$sqlarea  where sql_id='ckxv7rd10nq3p';
--where executions > 500000

 /*================VERIFICAÇÃO DE TRANSAÇÕES ABERTAS POR USUÁRIO =====================*/
 col action format a30
SELECT s.inst_id,s.action,s.sid,s.serial#,s.status,s.event,t.status "TRANSACTION STATUS"
FROM gv$transaction t, gv$session s
WHERE t.ses_addr = s.saddr
AND s.sid=1348;
/*=====================================*/

--ACTIVE SESSIONS
select inst_id,sid,serial#,username,status,event from gv$session where username is not null and status='ACTIVE' and username != 'SYS'
order by sid;

--VERIFICANDO WAITS


--contagem
SELECT SW.EVENT, SW.STATE, COUNT(*) FROM GV$SESSION_WAIT SW, GV$SESSION S 
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND S.USERNAME IS NOT NULL
AND S.USERNAME IN ('SA_PROTHEUS11')
GROUP BY SW.EVENT, SW.STATE
ORDER BY 3 DESC;

SELECT SW.EVENT, SW.STATE, COUNT(*) FROM GV$SESSION_WAIT SW, GV$SESSION S 
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND S.USERNAME IS NOT NULL
AND S.USERNAME NOT IN ('DBSNMP','SYSMAN','SYS')
GROUP BY SW.EVENT, SW.STATE
ORDER BY 3 DESC;

--evento especifico
SELECT s.sid,s.serial#,s.username,SW.EVENT, SW.STATE, SW.SECONDS_IN_WAIT/60 as MINUTES_WAIT FROM GV$SESSION_WAIT SW, GV$SESSION S 
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND S.USERNAME IS NOT NULL
AND S.USERNAME IN ('TOTVS10','NFE')
AND SW.EVENT='db file sequential read'
ORDER BY 3 DESC;


SELECT SW.INST_ID,SW.EVENT, SW.STATE, SW.COUNT(*) FROM GV$SESSION_WAIT;

--SINCE INSTANCE STARTUP:
--by instance,class and average_wait
set lines 160
set numwidth 18
col wait_class for a15
col event for a60
col inst_id format a7
col inst_id format 9999
col total_waits for 999,999,999
col total_timeouts for 999,999,999
col time_waited for 999,999,999,999
col average_wait for 999,999,999,999

select se.inst_id,i.startup_time,e.wait_class, se.event, se.total_waits, se.time_waited, se.average_wait
from gv$system_event se, gv$instance i, v$event_name e
where i.inst_id=se.inst_id
and e.event_id=se.event_id
and e.wait_class != 'Idle'
order by average_wait;

--AVERAGE SINGLE BLOCK READS LATENCY - HISTORY (ENTERPRISE)
--select * from v$sysmetric_history where metric_id=2144;

--
select a.begin_time, a.end_time, round(((a.value + b.value)/131072),2) "GB per sec"
from v$sysmetric a, v$sysmetric b
where a.metric_name = 'Logical Reads Per Sec'
and b.metric_name = 'Physical Reads Direct Per Sec'
and a.begin_time = b.begin_time 
/

-- GET SQL_ID (SQL) EXCUTION PLAN
col object_name format a20
col id format 99
SELECT SQL_ID, TIMESTAMP,PLAN_HASH_VALUE, ID, OPERATION, OBJECT_NAME, CARDINALITY, BYTES, COST, CPU_COST, IO_COST, TIME
FROM GV$SQL_PLAN
WHERE SQL_ID='arazgbrayqbcd'
ORDER BY PLAN_HASH_VALUE,timestamp,ID;

/**************************ENABLE/DISABLE SQL TRACE*****************************/ 

exec dbms_system.set_sql_trace_in_session(&SID,&SERIAL,true);
exec dbms_system.set_sql_trace_in_session(&SID,&SERIAL,false);

execute dbms_monitor.session_trace_enable(session_id=>&SID,serial_num=>&SERIAL,waits=>true,binds=>true);
execute dbms_monitor.session_trace_disable(session_id=>&SID,serial_num=>&SERIAL);
--------select * from v$session where username='TOTVS10' and module !='SQL Developer';
--ENCONTRAR TRACE:

SELECT B.SID, B.SERIAL# ,A.PID, A.PROGRAM, A.TRACEFILE FROM
GV$PROCESS  A, GV$SESSION B
WHERE A.ADDR = B.PADDR
AND B.SID=&SID
and B.INST_ID=&INST_ID;


execute dbms_monitor.session_trace_enable(session_id=>18,serial_num=>44801,waits=>true,binds=>true);
execute dbms_monitor.session_trace_disable(session_id=>18,serial_num=>44801);


-- ENCONTRAR MEU SID:
select 
   sys_context('USERENV','SID') 
from dual;

/*******************SELECTS WENDEL*****************************/ 

## Find session by OS pid
col machine format a20
select a.username usr_unix,b.username,b.sid ,b.serial#,b.machine,b.status, spid processo, a.program, b.sql_id ,b.username usr_ora,b.inst_id,b.wait_class
from  gv$process  a, gv$session b
where A.ADDR = B.PADDR
and a.spid in (&SPID)
order by 3;

SELECT 
   T2.ORACLE_USERNAME ,
   T1.NAME,
   DECODE(T2.LOCKED_MODE,   0, 'NONE',1, 'NULL',2, 'ROW-S (SS)', 3, 'ROW-X (SX)',   4, 'SHARE',5, 'S/ROW-X (SSX)',6, 'EXCLUSIVE','NONE') TIPO,
   DECODE(T3.LOCKWAIT,NULL,'LOCKED','WAITING') STATUS,
   T2.OS_USER_NAME ,
   T2.SESSION_ID,
   T3.MACHINE,
   T3.PROGRAM,
   T3.SID,
   T3.SERIAL#,
    TO_CHAR(T3.LOGON_TIME,'DD/MM/YYYY HH24:MI:SS') "DATA DA CONEXÃO"
FROM
   V$LOCKED_OBJECT T2,
   V$SESSION T3,
   SYS.OBJ$ T1
WHERE
   T2.OBJECT_ID = T1.OBJ# AND
   T2.SESSION_ID = T3.SID
   AND t3.sid=242
ORDER BY
   T2.ORACLE_USERNAME,   T1.NAME;

   
 /* MEU SELECT DE LOCKS */
col lock_type format a12
col mode_held format a10
col mode_requested format a10
col blocking_others format a20
col username format a10

SELECT session_id,lock_type, mode_held, mode_requested, blocking_others, lock_id1
FROM dba_lock l
WHERE blocking_others <> 'Not Blocking' AND lock_type NOT IN ('Media Recovery', 'Redo Thread')
and mode_held='Exclusive';

SELECT l1.sid ||' (Instance '|| l1.INST_ID || ') is blocking ' || l2.sid||' (Instance '|| l2.INST_ID || ')' blocking_sessions
FROM gv$lock l1, gv$lock l2
WHERE
   l1.block = 1 AND
   l2.request > 0 AND
   l1.id1 = l2.id1 AND
   l1.id2 = l2.id2
   and l1.inst_id=l2.inst_id;

-- view all currently locked objects by the session:
/*
--The TM resource, known as the DML enqueue, is acquired during the execution of a statement when referencing a table so that the table is not 
dropped or altered during the execution of it.
--The TX resource, known as the transaction enqueue, is acquired exclusive when a transaction initiates its first change and is held until the 
transaction does a COMMIT or ROLLBACK. Row locking is based on TX enqueues. PMON will mark a transaction status as dead in the undo segment header. 
At that point the TX enqueue associated with that transaction is also released. PMON will then attempt to rollback some of the changes associated 
with the "dead" transaction, but will then pass it to SMON to apply the remainder of the associated undo records. 
--FAQ: Detecting and Resolving Locking Conflicts and Ora-00060 errors (Doc ID 15476.1)
*/
col obj_owner format a12
col object_name format a25
col u_name format a15
col osuser format a10
col status format a12
col locktype format a19
col mode_help format a13
SELECT s.inst_id,s.sid,s.serial#,username U_NAME, owner OBJ_OWNER, object_name, object_type, s.osuser,
DECODE(l.block,
  0, 'Not Blocking',
  1, 'Blocking',
  2, 'Global') STATUS,
DECODE(l.type,
  'TM', 'DML Enqueue',
  'TX', 'Transaction Enqueue',
  'UL', 'User supplied') LOCKTYPE,
  DECODE(v.locked_mode,
    0, 'None',
    1, 'Null',
    2, 'Row-S (SS)',
    3, 'Row-X (SX)',
    4, 'Share',
    5, 'S/Row-X (SSX)',
    6, 'Exclusive', TO_CHAR(lmode)
  ) MODE_HELD
FROM gv$locked_object v, dba_objects d,
gv$lock l, gv$session s
WHERE v.object_id = d.object_id
AND (v.object_id = l.id1)
AND v.session_id = s.sid
AND v.session_id = 1422 
and v.inst_id=s.inst_id
--and d.object_name='CT1CMP'
ORDER BY username, session_id;

-- list objects that have been 
-- locked for 60 seconds or more: 
col "HOLDING Object" format a20
col WSID format a10
col "WAITING User" format a15
col "OS User" format a10
col "HOLDING Client" format a10
col HSID format a10
col "WAITING Program" format a30
col "WAITING Client" format a10
SELECT SUBSTR(TO_CHAR(w.session_id),1,5) WSID, p1.spid WPID,
SUBSTR(s1.username,1,12) "WAITING User",
SUBSTR(s1.osuser,1,8) "OS User",
SUBSTR(s1.program,1,20) "WAITING Program",
s1.client_info "WAITING Client",
SUBSTR(TO_CHAR(h.session_id),1,5) HSID, p2.spid HPID,
SUBSTR(s2.username,1,12) "HOLDING User",
SUBSTR(s2.osuser,1,8) "OS User",
SUBSTR(s2.program,1,20) "HOLDING Program",
s2.client_info "HOLDING Client",
o.object_name "HOLDING Object"
FROM gv$process p1, gv$process p2, gv$session s1,
gv$session s2, dba_locks w, dba_locks h, dba_objects o
WHERE w.last_convert > 60
AND h.mode_held != 'None'
AND h.mode_held != 'Null'
AND w.mode_requested != 'None'
AND s1.row_wait_obj# = o.object_id
AND w.lock_type(+) = h.lock_type
AND w.lock_id1(+) = h.lock_id1
AND w.lock_id2 (+) = h.lock_id2
AND w.session_id = s1.sid (+)
AND h.session_id = s2.sid (+)
AND s1.paddr = p1.addr (+)
AND s2.paddr = p2.addr (+)
ORDER BY w.last_convert DESC;

--MAIS UM
SELECT vh.sid locking_sid,
 vs.status status,
 vs.program program_holding,
 vw.sid waiter_sid,
 vsw.program program_waiting
FROM v$lock vh,
 v$lock vw,
 v$session vs,
 v$session vsw
WHERE     (vh.id1, vh.id2) IN (SELECT id1, id2
 FROM v$lock
 WHERE request = 0
 INTERSECT
 SELECT id1, id2
 FROM v$lock
 WHERE lmode = 0)
 AND vh.id1 = vw.id1
 AND vh.id2 = vw.id2
 AND vh.request = 0
 AND vw.lmode = 0
 AND vh.sid = vs.sid
 AND vw.sid = vsw.sid;

--OBJETOS BLOQUEADOS
select lo.XIDUSN, obj.owner# ,lo.OBJECT_ID, obj.name, lo.PROCESS, lo.SESSION_ID, lo.OS_USER_NAME, lo.ORACLE_USERNAME  from v$locked_object lo, obj$ obj
where lo.object_id=obj.obj#
AND NAME='LIVSAIDA'

/*************************SELECT DE LOCKS DO JEAN****************************/
 --2510, 2092
 set lines 200;
 col objeto format a30;
 col kill format a50
 col horalogin format a25
 col usuarioos format a15
 col usuario format a20
 col programa format a20
SELECT DISTINCT DOJ.object_name Objeto
      ,LOB.oracle_username Usuario
      ,LOB.os_user_name UsuarioOS
      ,SES.status Status
      ,TO_CHAR(SES.logon_time,'dd.mm.yyyy hh24:mi:ss') HoraLogin
      ,SES.sid
      ,SES.serial#
      ,'ALTER SYSTEM KILL SESSION '|| ''''||SES.sid||','||SES.serial#||''''||';' "Kill"
      ,SES.module PROGRAMA
  FROM V$LOCKED_OBJECT LOB
      ,dba_objects     DOJ
      ,v$session       SES
 WHERE LOB.object_id       = DOJ.object_id
   AND LOB.oracle_username = SES.username
   AND LOB.session_id      = SES.sid;
   --AND DOJ.OBJECT_NAME     = 'CTLUNIDA';

--TESTES
    set lines 200;
 col objeto format a30;
 col kill format a50
 col horalogin format a25
 col usuarioos format a15
 col usuario format a20
 col programa format a20
SELECT DISTINCT DOJ.object_name Objeto,LOB.oracle_username Usuario,LOB.os_user_name UsuarioOS,SES.status Status
      ,TO_CHAR(SES.logon_time,'dd.mm.yyyy hh24:mi:ss') HoraLogin,SES.sid,SES.serial#
      ,'ALTER SYSTEM KILL SESSION '|| ''''||SES.sid||','||SES.serial#||',@'||INST_ID||''''||';' "Kill"
      ,SES.module PROGRAMA
  FROM GV$LOCKED_OBJECT LOB ,dba_objects DOJ,gv$session SES
 WHERE LOB.object_id       = DOJ.object_id
   AND LOB.oracle_username = SES.username
   AND LOB.session_id      = SES.sid;


--MONITORAMENTO DE MODIFICAÇÕES UTILIZADO PELO OPTIMIZER
 select TABLE_OWNER,TABLE_NAME,INSERTS,UPDATES,DELETES,TIMESTAMP,TRUNCATED,DROP_SEGMENTS from dba_tab_modifications where table_owner <> 'SYS';