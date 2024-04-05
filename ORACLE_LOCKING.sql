--ORACLE LOCKING
col machine format a30
col action format a30
 select INST_ID,sid, serial#, username, osuser,ACTION,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID,EVENT,wait_class,p1text,p2text,p3text,
 BLOCKING_SESSION,FINAL_BLOCKING_SESSION,seconds_in_wait,SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID
 from gv$session 
 WHERE USERNAME IS NOT NULL
 and STATUS='ACTIVE'
 --AND SID=632
--AND USERNAME = 'PROTOTIPO';


---ACTIVE SESSIONS LIST
col machine format a30
col action format a30
col osuser format a15
col username format a20
col p1text format a15
col p3text format a15
col inst_id format 9999
col wait_class format a30
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';
 select INST_ID,sid, serial#, username, osuser, logon_time,ACTION,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID,EVENT,wait_class,p1text,p2text,p3text,
 --BLOCKING_SESSION,FINAL_BLOCKING_SESSION,SECONDS_IN_WAIT,SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID
 BLOCKING_SESSION,FINAL_BLOCKING_SESSION,WAIT_TIME_MICRO/1000000 as "WAIT(S)",SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID
 from gv$session 
 WHERE STATUS = 'ACTIVE'
 and USERNAME IS NOT NULL
 AND USERNAME != 'SYS'
 --AND USERNAME='SYS'
 --and sid=386;
 -----

SELECT INST_ID,sid, serial#, username, osuser, logon_time,ACTION,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID,EVENT,wait_class,p1text,p2text,p3text,
 BLOCKING_SESSION,FINAL_BLOCKING_SESSION,WAIT_TIME_MICRO/1000000,SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID 
FROM gv$session 
where sid=250 
and serial#=39515;

---ACTIVE SESSIONS LIST, ORDERED BY SECONDS_IN_WAIT (10G) OR WAIT_TIME_MICRO (11G)

col machine format a30
col action format a30
col osuser format a15
col username format a20
col p1text format a15
col p3text format a15
col inst_id format 9999
col wait_class format a30
 select 
 --SECONDS_IN_WAIT, --(10G)
 WAIT_TIME_MICRO/1000000 "TIME_WAITING(S)", --(11G)
 INST_ID,sid, serial#, username, osuser,ACTION,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID,EVENT,wait_class,p1text,p2text,p3text,
 BLOCKING_SESSION,FINAL_BLOCKING_SESSION,SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID
 from gv$session 
 WHERE USERNAME IS NOT NULL
 and STATUS='ACTIVE'
 --AND WAIT_TIME_MICRO/1000000 >= 1
 --AND USERNAME = 'TOTVS_RO'
 AND USERNAME != 'SYS'
 order by 1;

 
 -- INCLUSIVE BACKGROUND
  select 
 --SECONDS_IN_WAIT, --(10G)
 WAIT_TIME_MICRO/1000000 "TIME_WAITING(S)", --(11G)
 INST_ID,sid, serial#, username, osuser,ACTION,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID,EVENT,wait_class,p1text,p2text,p3text,
 BLOCKING_SESSION,FINAL_BLOCKING_SESSION,SQL_EXEC_ID,PREV_SQL_ADDR,PREV_SQL_ID
 from gv$session 
 WHERE-- USERNAME IS NOT NULL
 STATUS='ACTIVE'
 --AND WAIT_TIME_MICRO/1000000 >= 1
 --AND USERNAME = 'SYS'
  --AND USERNAME != 'SYS'
 order by 1;
 
 ---RESUME

col machine format a30
col action format a30
col username format a20
col osuser format a20
col inst format a4
col inst format 9999
 select INST_ID inst,sid, serial#, username, osuser,ACTION,LOCKWAIT,STATUS,MACHINE,PROGRAM,SQL_ID,EVENT,wait_class, '### '||wait_time,
 BLOCKING_SESSION,FINAL_BLOCKING_SESSION,PREV_SQL_ID
 from gv$session 
 WHERE STATUS = 'ACTIVE'
 and USERNAME IS NOT NULL
 AND USERNAME != 'SYS'
 and SID=853;

 ------


Detecting and Resolving Locking Conflicts using TopSessions (Doc ID 164760.1)

--QUEM ESTA ESPERANDO POR QUEM?
 

--QUEM ESTA SEGURANDO OBJETOS EM UMA TRANSACAO A MAIS DE 10MIN?
select * from gv$lock where type='TM' and CTIME>600;

/*
INST_ID - ID da instancia (RAC)
L.ADDR - 
L.KADDR - 
L.SID - SID da sessão em questão
L.TYPE - Tipo de lock
L.ID1 - depende, pesquisando
*/
SELECT L.INST_ID,L.ADDR,L.KADDR,L.SID,L.TYPE,L.ID1,L.ID2,L.LMODE LOCKED_MODE,L.REQUEST REQUESTED_MODE,L.CTIME,L.BLOCK 
FROM GV$LOCK L, GV$SESSION S
WHERE L.TYPE != 'AE'
AND L.TYPE != 'MR'
AND S.INST_ID=L.INST_ID
AND S.SID=L.SID
AND S.USERNAME IS NOT NULL;


select /*+ ORDERED */
l.sid, l.lmode, TRUNC(l.ctime/60) min_blocked, u.name||'.'||o.NAME blocked_obj
from (select * from v$lock
where type='TM'
and sid in (select sid
from v$lock
where block!=0)) l
, sys.obj$ o
where o.obj# = l.ID1
and o.OWNER# = u.user#
/

--WHO'S LOCKING WHO
SELECT l1.sid ||' (Instance '|| l1.INST_ID || ') is blocking ' || l2.sid||' (Instance '|| l2.INST_ID || ')' blocking_sessions
FROM gv$lock l1, gv$lock l2
WHERE
   l1.block = 1 AND
   l2.request > 0 AND
   l1.id1 = l2.id1 AND
   l1.id2 = l2.id2
   and l1.inst_id=l2.inst_id;

-- WHO's LOCKING WHO AND WHAT OBJECT IS WAITING ON
col machine format a20
col username format a15
col asking_for format a20
WITH LOCKERS (
  FINAL_SESS,WHOSLOCKING, INST_ID, SID, USERNAME, MACHINE,ASKING_FOR,STATUS,"TIME_WAITING(S)",SQL_ID,PREV_SQL_ID
) as (
 select nvl(final_blocking_session,sid),'I''M LOCKING' as WHOSLOCKING,inst_id,SID,username,machine,'' as ASKING_FOR,
 status,round(WAIT_TIME_MICRO/1000000) "TIME_WAITING(S)",sql_id,prev_sql_id
 from gv$session where final_blocking_session is null 
	and sid in (select final_blocking_session from gv$session)
 union all
 select sess.final_blocking_session,'I''m Waiting',sess.inst_id,sess.SID,sess.username,sess.machine,obj.object_name,sess.status,round(SESS.WAIT_TIME_MICRO/1000000),sess.sql_id,sess.prev_sql_id
 from lockers lck
 join gv$session sess
 on lck.sid=sess.final_blocking_session
 and sess.final_blocking_session is not null
 join gv$lock l on sess.sid=l.sid and sess.inst_id=l.inst_id
 and l.type='TX' and l.request!=0
 join gv$locked_object lo on lo.xidsqn=l.id2
 join dba_objects obj on lo.object_id=obj.object_id
)
 select * from LOCKERS
 order by 1,2;
 
-- select * from v$lock where sid=&SID;
   
--COMANDO VOLTARÁ APENAS SE HOUVER LOCKS PARA O USUARIO SELECIONADO

col wait_class format a30
col machine format a20
col username format a20
col program format a20
col osuser format a30
col os_commando format a20
select s.sid,s.serial#,s.username,s.machine,s.osuser,s.status,s.program,s.sql_id,s.wait_class,s.BLOCKING_SESSION,s.FINAL_BLOCKING_SESSION,s.WAIT_TIME_MICRO/1000000 as wait_seconds, proc.spid as OS_PROC_BLOCKING, 'kill -9 '||proc.spid as OS_COMMAND, slock.username as blocking_user, slock.status as blocking_status
from gv$session s, gv$process proc, gv$session slock
where s.username='RADIUS' --USUARIO COM LOCK
and s.BLOCKING_SESSION is not null
and s.FINAL_BLOCKING_SESSION=slock.sid
and proc.ADDR = (select paddr from gv$session where sid=s.FINAL_BLOCKING_SESSION)
order by 3;


--WAITS
SELECT s.inst_id,s.USERNAME,SW.EVENT, SW.STATE, COUNT(*) FROM GV$SESSION_WAIT SW, GV$SESSION S 
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND S.USERNAME IS NOT NULL
--AND S.USERNAME IN ('TEKNISA')
--AND S.USERNAME NOT IN ('SYS','SYSMAN','DBSNMP')
--AND SW.EVENT <> 'SQL*Net message from client'
GROUP BY s.inst_id,s.USERNAME,SW.EVENT, SW.STATE
ORDER BY 4 DESC;

--WAITS BY SQL_ID
SELECT S.SQL_ID,SW.EVENT, SW.STATE, COUNT(*) FROM GV$SESSION_WAIT SW, GV$SESSION S 
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND S.USERNAME IS NOT NULL
--AND S.USERNAME IN ('TASY')
AND SW.EVENT <> 'SQL*Net message from client'
--AND SW.EVENT like '%library%'
GROUP BY s.sql_id,s.USERNAME,SW.EVENT, SW.STATE
ORDER BY 4, 1;

--WAITS BY SQL_ID with command

-- ###COM ERRO
col event format a50
SELECT isql.sql_id, isql.event, isql.state, isql.count, sqla.sql_fulltext 
FROM v$sqlarea sqla, (SELECT S.SQL_ID sql_id,SW.EVENT event, SW.STATE state, COUNT(*) count
	FROM GV$SESSION_WAIT SW, GV$SESSION S
	WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
	AND S.USERNAME IS NOT NULL
	AND S.USERNAME IN ('TASY')
	--AND SW.EVENT <> 'SQL*Net message from client'
	AND SW.EVENT like '%library%'
	GROUP BY s.sql_id,s.USERNAME,SW.EVENT, SW.STATE) isql
WHERE sqla.SQL_ID = isql.SQL_ID;

--select sql_fulltext from v$sqlarea where sql_id='br9tpw2rjvmt9';

--LOCKED OBJECTS - BLOCKING
col object_name format a30
col u_name format a12
SELECT s.sid,username U_NAME, owner OBJ_OWNER, object_name, object_type, s.osuser,
DECODE(l.block, 0, 'Not Blocking', 1, 'Blocking', 2, 'Global') STATUS,
DECODE(v.locked_mode, 0, 'None', 1, 'Null', 2, 'Row-S (SS)', 3, 'Row-X (SX)', 4, 'Share', 5, 'S/Row-X (SSX)', 6, 'Exclusive', TO_CHAR(lmode)
  ) MODE_HELD
FROM gv$locked_object v, dba_objects d, gv$lock l, gv$session s
WHERE v.object_id = d.object_id
AND ( v.object_id = l.id1 )
AND l.block <> 0
AND v.session_id = s.sid
--AND s.sid=162
ORDER BY username, session_id;

--LOCKED OBJECTS
col object_name format a20
col machine format a12
col program format a15
col username format a12
SELECT O.OBJECT_NAME, L.LOCKED_MODE, L.SESSION_ID, S.SERIAL#, P.SPID, S.PROGRAM,S.USERNAME,
S.MACHINE,S.PORT , S.LOGON_TIME,SQ.SQL_FULLTEXT 
FROM V$LOCKED_OBJECT L, DBA_OBJECTS O, V$SESSION S, 
V$PROCESS P, V$SQLAREA SQ 
WHERE L.OBJECT_ID = O.OBJECT_ID 
AND L.SESSION_ID = S.SID AND S.PADDR = P.ADDR 
AND S.SQL_ID = SQ.SQL_ID
AND O.OBJECT_NAME IN ('RECTITRC','CORDEBRT');
--AND O.OBJECT_NAME='RECTITRC';


select L.SESSION_ID, S.SERIAL#,L.PROCESS,S.PROGRAM,S.USERNAME,S.MACHINE,S.LOGON_TIME,SQ.SQL_FULLTEXT
FROM V$LOCKED_OBJECT L, DBA_OBJECTS O, V$SESSION S, V$PROCESS P, V$SQLAREA SQ 
WHERE L.OBJECT_ID = O.OBJECT_ID
AND S.SID=L.SESSION_ID
AND SQ.SQL_ID=S.SQL_ID
AND O.OBJECT_NAME IN ('RECTITRC','CORDEBRT');

--SQL WAITING ON SPECIFIC EVENT
select event, sql_id, count(*),
avg(time_waited) avg_time_waited
from v$active_session_history
where event like nvl('&event','%more data from%')
group by event, sql_id
order by event, 3
/
--Enter value for event: library cache lock

--IF THE SQL IS NOT IN SQL_AREA:
select distinct * from v$open_cursor
 where rownum < 10
 and sql_id = '&sqlid';


--REMOTE SESSIONS (ORIGIN, DESTINY, REMOTE SESSION, WAIT)

Select
substr(s.ksusemnm,1,10)||'-'|| substr(s.ksusepid,1,10)      "ORIGIN",
substr(g.K2GTITID_ORA,1,35)                                 "GTXID",
substr(s.indx,1,4)||'.'|| substr(s.ksuseser,1,5)            "LSESSION" ,
s2.username,
substr(
  decode(bitand(ksuseidl,11),
     1,'ACTIVE',
     0, decode( bitand(ksuseflg,4096) , 0,'INACTIVE','CACHED'),
     2,'SNIPED',
     3,'SNIPED',
     'KILLED'
  ),1,1
) "S", substr(w.event,1,10) "WAITING"
from  
  x$k2gte g,  x$ktcxb t,  x$ksuse s,  v$session_wait w,  v$session s2
where    g.K2GTDXCB =t.ktcxbxba
and    g.K2GTDSES=t.ktcxbses
and    s.addr=g.K2GTDSES
and    w.sid=s.indx
and  s2.sid = w.sid;

 --------

 SELECT s.inst_id,s.sid,s.serial#,s.USERNAME,SW.EVENT, SW.STATE, S.SQL_ID, COUNT(*) FROM GV$SESSION_WAIT SW, GV$SESSION S 
WHERE S.SID=SW.SID AND SW.INST_ID=S.INST_ID
AND S.USERNAME IS NOT NULL
AND S.USERNAME IN ('AVI','MMD','RAM')
--AND S.USERNAME NOT IN ('SYS','SYSMAN','DBSNMP')
AND SW.EVENT <> 'SQL*Net message from client'
GROUP BY s.inst_id,s.sid,s.serial#,s.USERNAME,SW.EVENT, SW.STATE, S.SQL_ID
ORDER BY 4 DESC;

