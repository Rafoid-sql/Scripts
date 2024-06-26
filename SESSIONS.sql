-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
---- Elapsed in microseconds ----
COL ELAPSED_TIME FOR 999999999999999
select * from (
 select  x.sql_id, z.sql_text, x.executions, x.exec_per_hour, x.elapsed_time, x.elapsed_time_per_exec 
   from ( 
     select dbid, sql_id, 
            sum(executions_delta) executions, 
            avg(exec_per_hour) exec_per_hour, 
            sum(elapsed_time) elapsed_time, 
            avg(elapsed_time_per_exec) elapsed_time_per_exec 
       from ( 
         select b.dbid,a.instance_number, b.sql_id, b.executions_delta, 
		        b.executions_delta/a.diff_hour exec_per_hour, 
                b.elapsed_time_delta elapsed_time, 
				b.elapsed_time_delta/b.executions_delta elapsed_time_per_exec 
           from (select snap_id, 
		                dbid,
						instance_number, 
						end_interval_time, 
						begin_interval_time, 
                        ROUND(TO_NUMBER(TO_DATE(TO_CHAR(end_interval_time,   'DDMMYYYY:HH24:MI:SS'), 'DDMMYYYY:HH24:MI:SS')  
                                       -TO_DATE(TO_CHAR(begin_interval_time, 'DDMMYYYY:HH24:MI:SS'), 'DDMMYYYY:HH24:MI:SS') ) * 24 ,2) diff_hour
                   from dba_hist_snapshot 
                  WHERE BEGIN_INTERVAL_TIME >= TO_DATE('21-07-2023 13:00', 'dd-mm-yyyy hh24:mi') 
                    AND END_INTERVAL_TIME   <= TO_DATE('21-07-2023 15:00', 'dd-mm-yyyy hh24:mi') 
                ) a, dba_hist_sqlstat b 
          where a.snap_id          = b.snap_id 
		    and a.dbid             = b.dbid 
			and a.instance_number  = b.instance_number 
            and b.executions_delta > 0 ) 
      group by dbid, sql_id ) x, dba_hist_sqltext z 
  where x.dbid = z.dbid and x.sql_id = z.sql_id 
  order by elapsed_time desc) 
where rownum <=10
=========================================================================================================================================
--Verify Jobs (detailed):
COL OBJECT_NAME FOR A20
COL PORT FOR 999999
COL MACHINE FOR A30
COL USERNAME FOR A10
COL SQL_FULLTEXT FOR A60
SELECT O.OBJECT_NAME, S.SID, S.SERIAL#, P.SPID, S.PROGRAM, S.USERNAME, S.MACHINE, S.PORT , S.LOGON_TIME, SQ.SQL_FULLTEXT
FROM V$LOCKED_OBJECT L, DBA_OBJECTS O, V$SESSION S, V$PROCESS P, V$SQL SQ
WHERE L.OBJECT_ID = O.OBJECT_ID AND L.SESSION_ID = S.SID AND S.PADDR = P.ADDR AND S.SQL_ADDRESS = SQ.ADDRESS;
=========================================================================================================================================
--Check active sessions
COL PID FOR A10
COL SID FOR A5
COL SER# FOR A5
COL STATUS FOR A10
COL BOX FOR A15
COL USERNAME FOR A20
COL SERVER FOR A10
COL OS_USER FOR A20
COL PROGRAM FOR A50
SELECT SUBSTR(A.SPID,1,9) PID, SUBSTR(B.SID,1,5) SID,SUBSTR(B.SERIAL#,1,5) SER#,SUBSTR(B.STATUS,1,7) STATUS, SUBSTR(B.MACHINE,1,6) BOX, SUBSTR(B.USERNAME,1,10) USERNAME, B.SERVER, SUBSTR(B.OSUSER,1,8) OS_USER, SUBSTR(B.PROGRAM,1,30) PROGRAM
FROM V$SESSION B, V$PROCESS A
WHERE B.PADDR = A.ADDR
AND TYPE = 'USER'
AND STATUS = 'ACTIVE'
ORDER BY SPID; 
=========================================================================================================================================
--Check inactive sessions
COL PID FOR A10
COL SID FOR A5
COL SER# FOR A5
COL STATUS FOR A10
COL BOX FOR A15
COL USERNAME FOR A20
COL SERVER FOR A10
COL OS_USER FOR A20
COL PROGRAM FOR A50
SELECT SUBSTR(A.SPID,1,9) PID, SUBSTR(B.SID,1,5) SID,SUBSTR(B.SERIAL#,1,5) SER#,SUBSTR(B.STATUS,1,8) STATUS, SUBSTR(B.MACHINE,1,20) BOX, SUBSTR(B.USERNAME,1,10) USERNAME, B.SERVER, SUBSTR(B.OSUSER,1,15) OS_USER, SUBSTR(B.PROGRAM,1,30) PROGRAM
FROM GV$SESSION B, GV$PROCESS A
WHERE B.PADDR = A.ADDR
AND TYPE = 'USER'
AND STATUS = 'INACTIVE'
AND OSUSER = 'weblogiccdes'
AND B.USERNAME = 'CDE'
ORDER BY SPID; 
=========================================================================================================================================
--CHECK RUNNING JOBS
SELECT J.SID, J.LOG_USER, J.JOB,J.BROKEN, J.FAILURES, J.LAST_DATE||':'||J.LAST_SEC LAST_DATE, J.THIS_DATE||':'||J.THIS_SEC THIS_DATE, J.NEXT_DATE||':'||J.NEXT_SEC NEXT_DATE, J.NEXT_DATE - J.LAST_DATE INTERVAL, J.WHAT
FROM (SELECT DJR.SID, DJ.LOG_USER, DJ.JOB, DJ.BROKEN, DJ.FAILURES, DJ.LAST_DATE, DJ.LAST_SEC, DJ.THIS_DATE, DJ.THIS_SEC, DJ.NEXT_DATE, DJ.NEXT_SEC, DJ.INTERVAL, DJ.WHAT FROM DBA_JOBS DJ, DBA_JOBS_RUNNING DJR WHERE DJ.JOB = DJR.JOB) J;
=========================================================================================================================================
--Check what is running
COL USERNAME FOR A20
COL OBJECT_NAME FOR A30
SELECT 'CALLED PLSQL', VS.USERNAME, D_O.OBJECT_NAME, VS.SID, VS.SERIAL#, VS.INST_ID
FROM DBA_OBJECTS D_O
INNER JOIN
GV$SESSION VS
 ON D_O.OBJECT_ID = VS.PLSQL_ENTRY_OBJECT_ID
UNION ALL
SELECT 'CURRENT PLSQL', VS.USERNAME, D_O.OBJECT_NAME, VS.SID, VS.SERIAL#, VS.INST_ID
FROM DBA_OBJECTS D_O
INNER JOIN
GV$SESSION VS
ON D_O.OBJECT_ID = VS.PLSQL_OBJECT_ID;
=========================================================================================================================================
--DBLINK Usage
SELECT SUBSTR(S.KSUSEMNM,1,10)||'-'|| SUBSTR (S.KSUSEPID,1,10) "ORIGIN", SUBSTR(G.K2GTITID_ORA,1,35) "GTXID", SUBSTR(S.INDX,1,4)||'.'|| SUBSTR(S.KSUSESER,1,5) "LSESSION", S2.USERNAME,
SUBSTR(
   DECODE(BITAND(KSUSEIDL,11),
      1,'ACTIVE',
      0, DECODE( BITAND(KSUSEFLG,4096) , 0,'INACTIVE','CACHED'),
      2,'SNIPED',
      3,'SNIPED',
      'KILLED'
   ),1,1
) "S",
SUBSTR(W.EVENT,1,10) "WAITING"
FROM X$K2GTE G,X$KTCXB T,X$KSUSE S,V$SESSION_WAIT W,V$SESSION S2
WHERE G.K2GTDXCB =T.KTCXBXBA
AND G.K2GTDSES=T.KTCXBSES
AND S.ADDR=G.K2GTDSES
AND W.SID=S.INDX
AND S2.SID = W.SID;
=========================================================================================================================================
--KILL SESSIONS
SET HEADING OFF
SELECT 'ALTER SYSTEM KILL SESSION '''||SID||','||SERIAL#||',@'||INST_ID||''' IMMEDIATE;'
FROM GV$SESSION
WHERE PROCESS NOT LIKE ('%BACKGROUND')
AND USERNAME IN ('IDM_USER_INFO')
--AND OSUSER IN ('AWahla1')
--AND OSUSER NOT IN ('ORACLE','SISTEMA')
--AND MACHINE IN ('HOSPLACI\WEKNOW-TESTE')
--AND MACHINE NOT IN ('HMRT\SERVER_DELL')
--AND STATUS IN ('ACTIVE','KILLED')
AND STATUS IN ('INACTIVE')
ORDER BY 1;
SET HEADING ON
=========================================================================================================================================
--DISCONNECT SESSIONS
SET HEADING OFF
SELECT 'ALTER SYSTEM DISCONNECT SESSION '''||SID||','||SERIAL#||',@'||INST_ID||''' IMMEDIATE;'
FROM GV$SESSION
WHERE PROCESS NOT LIKE ('%BACKGROUND')
--AND USERNAME IN ('IDM_USER_INFO')
--AND OSUSER IN ('AWahla1')
--AND OSUSER NOT IN ('ORACLE','SISTEMA')
--AND MACHINE IN ('HOSPLACI\WEKNOW-TESTE')
--AND MACHINE NOT IN ('HMRT\SERVER_DELL')
--AND STATUS IN ('ACTIVE','KILLED')
--AND SID IN (1327)
--AND SERIAL# IN (3072)
--AND STATUS IN ('INACTIVE')
AND STATUS IN ('KILLED')
ORDER BY 1;
SET HEADING ON
=========================================================================================================================================
-- Kill sessions AWS
BEGIN
    RDSADMIN.RDSADMIN_UTIL.KILL(
        SID    => &SID,
        SERIAL => &SERIAL_NUMBER,
        METHOD => 'IMMEDIATE');
END;
/
=========================================================================================================================================
-- Check Session Details
COL NODE FOR 99
COL FROM_WHERE FOR A35
COL SID_SER FOR A12
COL PROGRAM FOR A35
COL OSUSER FOR A12
COL SQL_TEXT FOR A50
SELECT INST_ID NODE,SID||','||SERIAL# SID_SER,SQL_ID,STATUS,SCHEMANAME||'@'||SERVICE_NAME FROM_WHERE,OSUSER,PROGRAM,NVL((SELECT DISTINCT SQL_TEXT FROM GV$SQL SQL WHERE SQL.SQL_ID = SES.SQL_ID),'NOTHING GOING ON') "SQL_TEXT",BLOCKING_SESSION,TO_CHAR(LOGON_TIME) FROM_WHEN
FROM GV$SESSION SES
WHERE TYPE IN ('USER')
--AND OSUSER NOT IN ('weblogiccdes')
--AND PROGRAM NOT LIKE ('JDBC Thin Client')
--AND SCHEMANAME LIKE ('%CHUB_CDES_USER%')
--AND SQL_ID IN ('7tusdy1ryjdc1','3tzpp57r4349s')
AND SID IN (1279)
--AND SCHEMANAME = 'BPMS_APP'
ORDER BY STATUS,OSUSER,PROGRAM;
=========================================================================================================================================
-- Check Session Details II
COL NODE FOR 99
COL FROM_WHERE FOR A35
COL SID_SER FOR A12
COL PROGRAM FOR A40
COL OSUSER FOR A15
SELECT INST_ID NODE,SID||','||SERIAL# SID_SER,SQL_ID,STATUS,SCHEMANAME||'@'||SERVICE_NAME FROM_WHERE,OSUSER,PROGRAM,BLOCKING_SESSION,TO_CHAR(LOGON_TIME) FROM_WHEN
FROM GV$SESSION SES
WHERE TYPE = 'USER'
--AND SID IN (1)
AND SCHEMANAME = 'CDE'
AND OSUSER LIKE 'weblogiccdes%'
ORDER BY STATUS,OSUSER,PROGRAM;
=========================================================================================================================================
-- GET USERS SESSION HISTORY
SET LINES 500 PAGES 9999 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON
COL START_TIME FOR A25
COL "SID/SER" FOR A11
COL INST FOR 9999
COL END_TIME FOR A25
COL ELAPSED_TIME FOR A25
COL MACHINE FOR A30
COL USER_ID FOR A25
COL EVENT FOR A40
COL USERNAME FOR A20
SELECT /*+ PARALLEL(ASH,12) */ INSTANCE_NUMBER AS INST, SESSION_ID||','||SESSION_SERIAL# "SID/SER", MACHINE, USERNAME, EVENT, MIN(SAMPLE_TIME) AS START_TIME, MAX(SAMPLE_TIME) AS END_TIME, MAX(SAMPLE_TIME)-MIN(SAMPLE_TIME) AS ELAPSED_TIME 
FROM DBA_HIST_ACTIVE_SESS_HISTORY ASH , DBA_USERS U 
WHERE ASH.USER_ID=U.USER_ID AND SQL_EXEC_START > SYSDATE - 30
AND USERNAME IN
(
'DBTUNE','EAIAPPADM','APP_M04','DIHDB','IHDB','DATAPOINT_EM','DATAPOINT_AUDIT','ORADBSEC','PMP_APP_USER','DATAPOINT','LCARVA14','SBHUYAN2','JGARCIA80','SGONUGU1','JNALLAM1','OVM_EDITOR','EIBATCH2','EIBATCH','EIAPP2','EIAPP','ORABACK','SVC_PRD_0225123_DSA','SKONDA2','NBOTTUR1','GFRANCI2','FCRUZ61','PMATOS1','CUPPALA3','SCH1','BPRADHA3','AMAZUMD2','DIP','HWD4127','DVILLAL1','VA295781'
)
GROUP BY INSTANCE_NUMBER, SESSION_ID, SESSION_SERIAL#, MACHINE, USERNAME, EVENT
ORDER BY USERNAME, START_TIME, END_TIME, MACHINE;
=========================================================================================================================================
--Check Process/Session Count History
COL SNAP_ID HEADING 'SNAP|ID' FOR A7
COL INSTANCE_NUMBER HEADING 'INST|#' FOR A4
COL CURRENT_UTILIZATION HEADING 'CURR|USE' FOR A6
COL MAX_UTILIZATION HEADING 'MAX|USE' FOR A6
COL BEGIN_INTERVAL_TIME HEADING 'BEGIN|INTERVAL' FOR A27
COL END_INTERVAL_TIME HEADING 'END|INTERVAL' FOR A27
COL RESOURCE_NAME HEADING 'RESOURCE|NAME' FOR A15
SELECT TO_CHAR(RL.SNAP_ID) SNAP_ID, S.BEGIN_INTERVAL_TIME, S.END_INTERVAL_TIME, TO_CHAR(RL.INSTANCE_NUMBER) INSTANCE_NUMBER, RL.RESOURCE_NAME, TO_CHAR(RL.CURRENT_UTILIZATION) CURRENT_UTILIZATION, TO_CHAR(RL.MAX_UTILIZATION) MAX_UTILIZATION
FROM DBA_HIST_RESOURCE_LIMIT RL, DBA_HIST_SNAPSHOT S
WHERE S.BEGIN_INTERVAL_TIME >= SYSDATE-7
AND S.END_INTERVAL_TIME <= SYSDATE
--AND S.SNAP_ID = RL.SNAP_ID AND RL.RESOURCE_NAME = 'processes'
AND S.SNAP_ID = RL.SNAP_ID AND RL.RESOURCE_NAME = 'sessions'
ORDER BY S.BEGIN_INTERVAL_TIME, RL.INSTANCE_NUMBER;
=========================================================================================================================================
--Check sql_id time to finish
COL INS FOR 999
COL SID/SER  FOR A11
COL TARGET FOR A20
COL "%_COMP" FOR A6
COL "T/S/R(min)" FOR A12
COL "SCHEMA" FOR A10
COL SQL_FULLTEXT FOR A40
COL CLIENT_TOOL FOR A20
COL MACHINE FOR A20
SELECT S.INST_ID INS, L.SID || ',' || L.SERIAL# "SID/SER", L.SQL_ID, OPNAME TARGET, TO_CHAR(ROUND((SOFAR/TOTALWORK),4)*100) "%_COMP",TO_CHAR(LOGON_TIME,'MON-DD HH24:MI:SS') LOGON_TIME,TO_CHAR(START_TIME,'MON-DD HH24:MI:SS') START_TIME, LAST_CALL_ET LAST_CALL, CEIL((ELAPSED_SECONDS+TIME_REMAINING)/60) || '/' || FLOOR(ELAPSED_SECONDS/60) || '/' || CEIL(TIME_REMAINING/60) "T/S/R(min)", A.SQL_FULLTEXT, A.PARSING_SCHEMA_NAME "SCHEMA", A.MODULE CLIENT_TOOL, S.MACHINE
FROM GV$SESSION_LONGOPS L, GV$SQLAREA A, GV$SESSION S
WHERE L.SQL_ID = A.SQL_ID
AND TOTALWORK > 0
AND A.USERS_EXECUTING > 0
AND L.SQL_ID = S.SQL_ID
AND L.SID = S.SID
AND L.SQL_ID IN ('8btjp409pajab')
--AND L.SQL_ID IN ('3tzpp57r4349s')
--AND L.SQL_ID = ('17u3y4gbdqsbk')
--AND L.SQL_ID IN ('0a96yuav1urfh')
--AND L.SQL_ID ='7xbzd7fp3w3xn'
--AND S.SID IN (3167)
AND SOFAR != TOTALWORK;
=========================================================================================================================================
COL SID/SER  FOR A11
COL USERNAME FOR A10
COL MODULE FOR A20
COL MACHINE FOR A30
SELECT INST_ID,USERNAME,SID || ',' || SERIAL# "SID/SER",LOGON_TIME, MODULE,OSUSER,LAST_CALL_ET,SQL_ID,STATUS,MACHINE 
FROM GV$SESSION 
WHERE USERNAME='CDE' 
AND SID IN (5140)
AND STATUS='ACTIVE';
=========================================================================================================================================
--Session Waits
COL USERNAME FOR A20
COL MACHINE FOR A60
COL EVENT FOR A60
COL W_CLASS FOR A10
COL W_TIME FOR 999999
COL S_WAIT FOR 999999
SELECT NVL(S.USERNAME, '(ORACLE)') AS USERNAME, S.SID || ',' || S.SERIAL# "SID/SER", S.SQL_ID, S.MACHINE, SW.EVENT, SW.WAIT_CLASS AS W_CLASS, SW.WAIT_TIME AS W_TIME, SW.SECONDS_IN_WAIT AS S_WAIT, SW.STATE
FROM GV$SESSION_WAIT SW, GV$SESSION S
WHERE  S.SID = SW.SID AND SW.SECONDS_IN_WAIT > 0
AND SW.INST_ID = S.INST_ID
--AND S.SID IN (4746)
ORDER BY S.SQL_ID,S.MACHINE,SW.SECONDS_IN_WAIT DESC;
=========================================================================================================================================
--Check waits:
SELECT INST_ID, EVENT, STATE, COUNT(*)
FROM GV$SESSION_WAIT
GROUP BY EVENT, STATE, INST_ID
ORDER BY 4 DESC;
=========================================================================================================================================
--Check for locks:
COL INST_ID FOR 9999 HEADING 'INST'
COL SIDSER FOR A12 HEADING 'SID/SERIAL'
COL USERNAME FOR A20 HEADING 'USER_ORA'
COL CONNECTION FOR A10
COL STATUS FOR A8
COL USER_UNIX FOR A9
COL MACHINE FOR A30
COL SPID FOR A9  HEADING 'PROCESS'
COL CONSISTENT_GETS FOR 999999999999 HEADING 'GETS'
COL BLOCK_CHANGES FOR 999999999999 HEADING 'CHANGES'
COL NAME FOR A15 HEADING 'COMMAND'
COL LOC FOR A4 HEADING 'LOCK'
COL EVENT FOR A30
SET PAUSE OFF
SET ECHO OFF
-----SELECT A.SID SID,A.SERIAL#,A.SQL_ADDRESS,
SELECT /*+ FIRST_ROWS */ A.INST_ID, A.SID || ',' || A.SERIAL# SIDSER, A.SQL_ID, A.USERNAME, DECODE (SUBSTR(A.OSUSER,1,9),'ORAUSER','C/S',SUBSTR(A.OSUSER,1,9)) USER_UNIX, DECODE (SUBSTR(A.TERMINAL,1,6),'WINDOW',MACHINE,MACHINE) MACHINE, TO_CHAR(LOGON_TIME,'HH24:MI:SS') CONNECTION, B.SPID, D.CONSISTENT_GETS, D.BLOCK_CHANGES, C.NAME, DECODE(A.LOCKWAIT,'','NO','YES') LOC, SUBSTR(A.EVENT,1,30) EVENT
---FROM GV$SESSION  A,GV$PROCESS B,AUDIT_ACTIONS C,GV$SESS_IO D,GV$SESSTAT E,GV$STATNAME F
FROM GV$SESSION A,GV$PROCESS B,AUDIT_ACTIONS C,GV$SESS_IO D
WHERE A.INST_ID=B.INST_ID
AND B.INST_ID=D.INST_ID
AND A.PADDR=B.ADDR
AND A.USERNAME!=' '
AND A.USERNAME NOT LIKE 'SYS%'
AND A.STATUS='ACTIVE'
AND A.COMMAND=C.ACTION
AND A.SID=D.SID
---AND D.INST_ID=E.INST_ID
---AND E.INST_ID=F.INST_ID
---AND A.SID=E.SID
---AND E.STATISTIC#=F.STATISTIC#
---AND E.STATISTIC#=12
---AND F.STATISTIC#=12
ORDER BY CONSISTENT_GETS;
=========================================================================================================================================
--Check for locks II:
COL OBJ_NAME FOR A30
COL OBJ_TYPE FOR A15
COL USERNAME FOR A15
COL "SID/SER" FOR A11
COL OSUSER FOR A20
COL PROGRAM FOR A30
COL TP FOR A2
COL LM FOR 99
COL RQ FOR 99
COL BL FOR 99
COL CTIME FOR 999999
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SELECT S.INST_ID, OBJECT_NAME OBJ_NAME, OBJECT_TYPE OBJ_TYPE, USERNAME, SESSION_ID || ',' || SERIAL# "SID/SER", OSUSER, PROGRAM, L.TYPE TP, LMODE LM, REQUEST RQ, BLOCK BL, CTIME
FROM GV$LOCKED_OBJECT V, DBA_OBJECTS O, GV$LOCK L, GV$SESSION S
WHERE S.SID=L.SID 
AND V.INST_ID = S.INST_ID
AND V.OBJECT_ID=O.OBJECT_ID 
AND L.ID1=O.OBJECT_ID 
AND L.SID=V.SESSION_ID 
--AND OBJECT_NAME NOT LIKE '%TMP'
ORDER BY CTIME ASC;
=========================================================================================================================================
--Check for locks III:
SELECT A.INST_ID, SID, C.SERIAL#, ORACLE_USERNAME, OS_USER_NAME,LOCKED_MODE,OBJECT_NAME,OBJECT_TYPE 
FROM GV$LOCKED_OBJECT A, DBA_OBJECTS B, GV$SESSION C  
WHERE A.OBJECT_ID = B.OBJECT_ID
AND A.SESSION_ID = C.SID
AND A.INST_ID = C.INST_ID;
=========================================================================================================================================
--Blocking sessions:
COL "HOLDER" FOR 999999
COL "WAITER" FOR A11
COL "CLASS" FOR A20
COL "WAIT" FOR 999999
COL PROCESS FOR A15
COL PROGRAM FOR A15
COL USERNAME FOR A20
COL OSUSER FOR A20
SELECT BLOCKING_SESSION as "HOLDER",BLOCKING_SESSION_STATUS "H_STATUS",SID || ',' || SERIAL# "WAITER",STATUS "W_STATUS",INST_ID,USERNAME,WAIT_CLASS "CLASS",SECONDS_IN_WAIT "WAIT",OSUSER,PROCESS,SUBSTR(PROGRAM,1,10) "PROGRAM", SQL_ID
FROM GV$SESSION
WHERE BLOCKING_SESSION IS NOT NULL
ORDER BY BLOCKING_SESSION;
=========================================================================================================================================
--Blocking sessions II:
COL SESS FOR A30
SELECT SUBSTR(DECODE(REQUEST,0,'Holder: ','Waiter: ')||SID,1,13) SESS,ID1,ID2,LMODE,REQUEST,TYPE,INST_ID
FROM GV$LOCK
WHERE (ID1,ID2,TYPE) IN (SELECT ID1,ID2,TYPE FROM GV$LOCK WHERE REQUEST>0)
ORDER BY ID1,REQUEST;
=========================================================================================================================================
--Blocking sessions III:
COL SESS FOR A30
SELECT SUBSTR(DECODE(REQUEST,0,'Holder: ','Waiter: ')||SID,1,13) SESS,ID1,ID2,LMODE,REQUEST,TYPE
FROM V$LOCK
WHERE (ID1,ID2,TYPE) IN (SELECT ID1,ID2,TYPE FROM V$LOCK WHERE REQUEST>0)
ORDER BY ID1,REQUEST;
=========================================================================================================================================
-- Check max processes/sessions:
COL VALUE FOR A40
select decode(name,'processes','CONFIGURED PROCESSES','sessions','CONFIGURED SESSIONS') as "CONFIG",to_char(value) as "VALUE"
from v$parameter where name in ('processes','sessions')
UNION ALL
select decode(resource_name,'processes','ACTIVE PROCESSES','sessions','ACTIVE SESSIONS') as "CONFIG", 
to_char(CURRENT_UTILIZATION) as "VALUE"
from v$resource_limit where resource_name in ('processes','sessions');
=========================================================================================================================================
--Check Session Count from users:
COL USERNAME FOR A20
COL MACHINE FOR A70
COL STATUS FOR A10
SELECT USERNAME,MACHINE,STATUS,COUNT(1) "SESSIONS" 
FROM GV$SESSION 
WHERE USERNAME IS NOT NULL
--AND USERNAME LIKE '%CDE%' 
--AND MACHINE LIKE '%ppollcdes000%'
AND STATUS IN ('INACTIVE')
GROUP BY USERNAME,MACHINE,STATUS
ORDER BY MACHINE, STATUS;
=========================================================================================================================================
--Check ACTIVE Session Count from users:
COL PROGRAM FOR A20
COL OSUSER FOR A15
COL INST FOR A4
COL SID FOR A5
COL LOGON_TIME FOR A25
COL MACHINE FOR A15
SELECT USERNAME,TO_CHAR(INST_ID) INST,TO_CHAR(SID) SID,MACHINE,PROGRAM,LOGON_TIME,OSUSER,SQL_ID 
FROM GV$SESSION 
WHERE STATUS='ACTIVE' 
AND USERNAME='CDE';
=========================================================================================================================================
--Currently active SQL:
COL SQL_TEXT FOR A100
SELECT S.USERNAME, S.SID, S.OSUSER, T.SQL_ID, SQL_TEXT
FROM V$SQLTEXT_WITH_NEWLINES T,V$SESSION S
WHERE T.ADDRESS =S.SQL_ADDRESS AND T.HASH_VALUE = S.SQL_HASH_VALUE AND S.STATUS = 'ACTIVE' AND S.USERNAME NOT IN ('SYSTEM','SYS','DBSNMP')
ORDER BY S.SID,T.PIECE;
=========================================================================================================================================
--Queries running for more than 60 seconds:
COL USERNAME FOR A20
COL SID FOR 999999
COL SER# FOR 999999
COL OSUSER FOR A15
COL SQL_TEXT FOR A100
SELECT S.USERNAME USERNAME,S.SID SID,S.SERIAL# AS SER#,S.OSUSER OSUSER,S.LAST_CALL_ET/60 MINS_RUNNING,Q.SQL_TEXT SQL_TEXT
FROM V$SESSION S JOIN V$SQLTEXT_WITH_NEWLINES Q ON S.SQL_ADDRESS = Q.ADDRESS
WHERE STATUS='ACTIVE' AND TYPE <>'BACKGROUND' AND LAST_CALL_ET> 60
ORDER BY SID,SERIAL#,Q.PIECE;
=========================================================================================================================================
--Which query is waiting:
SELECT SID, SQL_TEXT
FROM V$SESSION S, V$SQL Q
WHERE SID IN (SELECT SID FROM V$SESSION WHERE STATE IN ('WAITING') AND WAIT_CLASS != 'IDLE' AND EVENT='ENQ: TX - ROW LOCK CONTENTION' AND (Q.SQL_ID = S.SQL_ID OR Q.SQL_ID = S.PREV_SQL_ID));
=========================================================================================================================================
-- CHECK IDLE TIME FOR INACTIVE CONNECTIONS
COL INST FOR A4
COL USERNAME FOR A20
SELECT TO_CHAR(INST_ID) INST, SID, USERNAME, STATUS, TO_CHAR(LOGON_TIME,'DD-MM-YY HH:MI:SS') "LOGON", FLOOR(LAST_CALL_ET/3600)||':'|| TO_CHAR(FLOOR(MOD(LAST_CALL_ET,3600)/60),'FM00')||':'|| TO_CHAR(MOD(MOD(LAST_CALL_ET,3600),60),'FM00') "IDLE", PROGRAM
FROM GV$SESSION
WHERE TYPE='USER'
ORDER BY LAST_CALL_ET;
=========================================================================================================================================
--Running Queries (%)
COL "%_COMP" FOR 99.99'%'
COL "SID/SER" FOR A11
COL TARGET FOR A20
COL "SOFAR/TOTAL" FOR A15
COL "ELAP/REMAIN" FOR A13
COL MESSAGE FOR A65
COL USERNAME FOR A10
COL OPNAME FOR A20
COL UNITS FOR A6
COL SQL_PLAN_OPTIONS FOR A15
COL SQL_PLAN_OPERATION FOR A15
SELECT ROUND(SOFAR/TOTALWORK*100,2) "%_COMP", ''||SID||','||SERIAL#||'' "SID/SER", OPNAME, TARGET,''||SOFAR||'/'||TOTALWORK||'' "SOFAR/TOTAL", TO_CHAR(START_TIME, 'dd/mm/yy') "START", TO_CHAR(LAST_UPDATE_TIME, 'dd/mm/yy') "LAST UPDATE", ''||ELAPSED_SECONDS||'/'||TIME_REMAINING||'' "ELAP/REMAIN", MESSAGE, USERNAME, SQL_ID, SQL_PLAN_OPERATION, SQL_PLAN_OPTIONS
FROM V$SESSION_LONGOPS
WHERE SOFAR <> TOTALWORK
ORDER BY TARGET,SID;
=========================================================================================================================================
-- USAGE % FOR SESSIONS AND PROCESSES I
COL INST FOR A4
COL RESOURCE_NAME FOR A15
COL CURRENT FOR A10
COL MAX FOR A10
COL LIMIT FOR A10
SELECT TO_CHAR(INST_ID) INST, RESOURCE_NAME, TO_CHAR(CURRENT_UTILIZATION) "CURRENT", TO_CHAR(MAX_UTILIZATION) "MAX", TO_CHAR(LTRIM(LIMIT_VALUE)) "LIMIT", ROUND(CURRENT_UTILIZATION/LIMIT_VALUE*100,1) PCT_USED
FROM GV$RESOURCE_LIMIT
WHERE RESOURCE_NAME IN ( 'sessions', 'processes')
ORDER BY INST;
=========================================================================================================================================
-- USAGE % FOR SESSIONS AND PROCESSES II
COL INST FOR A4
COL RESOURCE FOR A15
COL "CURRENT (LIMIT)" FOR A20
COL PCT_USED FOR A10
SELECT TO_CHAR(INST_ID) INST, RESOURCE_NAME "RESOURCE", TO_CHAR(CURRENT_UTILIZATION) ||' ('|| TO_CHAR(LTRIM(LIMIT_VALUE)) ||')' "CURRENT (LIMIT)" , ROUND(CURRENT_UTILIZATION/LIMIT_VALUE*100,2)||'%' PCT_USED
FROM GV$RESOURCE_LIMIT
WHERE RESOURCE_NAME IN ( 'sessions', 'processes')
ORDER BY INST;
=========================================================================================================================================
-- LIST TYPES OF PROCESSES
COL USERNAME FOR A20
COL PROCESSES# FOR A10
COL PCT_USED FOR 990D00
COL INST FOR A4
WITH PROCESSES AS (
SELECT TO_CHAR(S.INST_ID) INST, NVL(S.USERNAME,'BACKGROUND') USERNAME, TO_CHAR(COUNT(NVL(S.USERNAME,'BACKGROUND'))) PROCESSES#
FROM GV$SESSION S, GV$PROCESS P
WHERE S.PADDR=P.ADDR
GROUP BY  S.INST_ID, NVL(S.USERNAME,'BACKGROUND'))
SELECT INST, USERNAME, PROCESSES#, ROUND((PROCESSES#/SUM(PROCESSES#) OVER ())*100,2) PCT_USED
FROM PROCESSES
ORDER BY 4;
=========================================================================================================================================  
-- USERS SESSION HISTORY:
SET LINES 300 PAGES 20000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON
COL "INST#" FOR 99
COL "SID/SER" FOR A11
COL MACHINE FOR A25
COL USERNAME FOR A20
COL EVENT FOR A35
COL "START" FOR A25
COL "END" FOR A25
COL "ELAPSED" FOR A25
COL OSUSER FOR A25
SELECT /*+ PARALLEL(ASH,12) */ INSTANCE_NUMBER "INST#", ''||SESSION_ID||','||SESSION_SERIAL#||'' "SID/SER", ASH.MACHINE, U.USERNAME/*, ASH.EVENT*/, MIN(SAMPLE_TIME) "START", MAX(SAMPLE_TIME) "END", MAX(SAMPLE_TIME)-MIN(SAMPLE_TIME) "ELAPSED", OSUSER
FROM DBA_HIST_ACTIVE_SESS_HISTORY ASH , DBA_USERS U, GV$SESSION SESS
WHERE ASH.USER_ID = U.USER_ID 
AND ASH.SQL_EXEC_START > SYSDATE - 7
AND SESS.OSUSER NOT IN ('root','oracle','SVC_PRD_TABLEAU','weblogiccdes','admadm')
AND 'ELAPSED' > 0
AND U.USERNAME IN ('CDE_READ')
GROUP BY INSTANCE_NUMBER, SESSION_ID, SESSION_SERIAL#, ASH.MACHINE, U.USERNAME/*, ASH.EVENT*/, OSUSER
ORDER BY USERNAME, "START", "END", MACHINE;
=========================================================================================================================================




SELECT NVL(SES.USERNAME,'ORACLE PROC')||' ('||SES.SID||')' USERNAME, SID, MACHINE, REPLACE(SQL.SQL_TEXT,CHR(10),'') STMT,
LTRIM(TO_CHAR(FLOOR(SES.LAST_CALL_ET/3600), '09')) || ':'
|| LTRIM(TO_CHAR(FLOOR(MOD(SES.LAST_CALL_ET, 3600)/60), '09')) || ':'
|| LTRIM(TO_CHAR(MOD(SES.LAST_CALL_ET, 60), '09'))    RUNT
FROM V$SESSION SES, V$SQLTEXT_WITH_NEWLINES SQL
WHERE SES.STATUS = 'ACTIVE'
AND SES.USERNAME IS NOT NULL
AND SES.SQL_ADDRESS    = SQL.ADDRESS
AND SES.SQL_HASH_VALUE = SQL.HASH_VALUE
AND SES.AUDSID <> USERENV('SESSIONID')
ORDER BY RUNT DESC, 1,SQL.PIECE; 
