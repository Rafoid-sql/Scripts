--Check usernames:
SET LINES 300
SET DEFINE OFF
COL USERNAME FOR A20
COL ACCOUNT_STATUS FOR A15
SELECT USERNAME,ACCOUNT_STATUS,EXPIRY_DATE
FROM DBA_USERS
WHERE ACCOUNT_STATUS NOT IN ('OPEN', 'EXPIRED & LOCKED');

--Retrieve oracle password:
SET LINES 300
SET PAGESIZE 1000
SET LONG 1000
SELECT DBMS_METADATA.GET_DDL('USER', USERNAME) --|| '/' USERCREATE
FROM DBA_USERS
WHERE USERNAME IN ('DADOSADV','PRISMA','MERCANET');

--Check users on v$session:
SELECT SID, SERIAL#, USERNAME, OSUSER, PROGRAM, STATUS, MACHINE
FROM V$SESSION
WHERE USERNAME='SENIORDBA';

--Verify Jobs (detailed):
SET LINES 300
SELECT O.OBJECT_NAME, S.SID, S.SERIAL#, P.SPID, S.PROGRAM, S.USERNAME, S.MACHINE, S.PORT , S.LOGON_TIME, SQ.SQL_FULLTEXT
FROM V$LOCKED_OBJECT L, DBA_OBJECTS O, V$SESSION S, V$PROCESS P, V$SQL SQ
WHERE L.OBJECT_ID = O.OBJECT_ID AND L.SESSION_ID = S.SID AND S.PADDR = P.ADDR AND S.SQL_ADDRESS = SQ.ADDRESS;

--Check which table is causing the error (ORA-00001: unique constraint (constraint_name) violated):
SELECT DISTINCT TABLE_NAME
FROM DBA_INDEXES
WHERE OWNER = 'OWNER_NAME' AND INDEX_NAME = 'CONSTRAINT_NAME';

--Kill datapump job:
DECLARE
   h1 NUMBER;
BEGIN
   h1 := DBMS_DATAPUMP.ATTACH('SYS_EXPORT_FULL_03','SYSTEM');
   DBMS_DATAPUMP.STOP_JOB (h1,1,0);
END;

--Matar sessões do banco
SELECT 'ALTER SYSTEM KILL SESSION '''||SID||','||SERIAL#||''' IMMEDIATE;'
FROM V$SESSION
WHERE PROCESS NOT LIKE ('%BACKGROUND')
--AND USERNAME IN ('VETORH_QA')
--AND OSUSER IN ('NGINX')
--AND OSUSER NOT IN ('ORACLE','SISTEMA')
--AND MACHINE IN ('HOSPLACI\WEKNOW-TESTE')
--AND MACHINE NOT IN ('HMRT\SERVER_DELL')
--AND STATUS IN ('ACTIVE','KILLED')
ORDER BY 1;

--Check all users:
SET LINES 200
SET PAGESIZE 2000
SELECT
SUBSTR(A.SPID,1,9) PID,
SUBSTR(B.SID,1,5) SID,
SUBSTR(B.SERIAL#,1,5) SER#,
SUBSTR(B.PROCESS,1,10) PROC,
SUBSTR(B.MACHINE,1,20) BOX,
SUBSTR(B.USERNAME,1,10) USERNAME,
SUBSTR(B.CLIENT_INFO,1,20) CLIENT,
SUBSTR(B.OSUSER,1,10) OS_USER,
SUBSTR(B.PROGRAM,1,30) PROGRAM,
SUBSTR(B.STATUS,1,10) STATUS
FROM V$SESSION B, V$PROCESS A
WHERE B.PADDR = A.ADDR
AND TYPE='USER'
--AND B.PROGRAM LIKE ('%rman%')
--AND CLIENT_INFO LIKE ('%69237192%')
--AND SID IN (6058)
--AND MACHINE IN ('HMRT\SERVER_DELL')
--AND STATUS IN ('KILLED')
ORDER BY SID;

--Check users on RAC:
SET LINES 250
COL USERNAME FOR A30
COL EVENT FOR A30
COL MACHINE FOR A20
COL OSUSER FOR A20
SELECT INST_ID, SID, SERIAL#, OSUSER, USERNAME, EVENT, MACHINE, LOCKWAIT, STATUS
FROM GV$SESSION
WHERE TYPE <>'BACKGROUND'
AND SID='775'
--AND STATUS = 'ACTIVE'
--AND OSUSER LIKE '%F08135%';

--Check sessions RAC:
SELECT COUNT(*), INST_ID
FROM GV$SESSION
WHERE TYPE='USER'
GROUP BY INST_ID;

--Currently active SQL:
SELECT S.USERNAME, S.SID, S.OSUSER, T.SQL_ID, SQL_TEXT
FROM V$SQLTEXT_WITH_NEWLINES T,V$SESSION S
WHERE T.ADDRESS =S.SQL_ADDRESS AND T.HASH_VALUE = S.SQL_HASH_VALUE AND S.STATUS = 'ACTIVE' AND S.USERNAME <> 'SYSTEM'
ORDER BY S.SID,T.PIECE;

--Check waits:
SET LINES 300
SET PAGESIZE 100
SELECT EVENT, STATE, COUNT(*)
FROM V$SESSION_WAIT
GROUP BY EVENT, STATE
ORDER BY 3 DESC;

--Check for locks:
SET LINES 300
SET PAGESIZE 500
COL OBJ_NAME FOR A30
COL OBJ_TYPE FOR A15
COL USERNAME FOR A15
COL "SID/SER" FOR A11
COL OSUSER FOR A20
COL PROGRAM FOR A40
COL TP FOR A2
COL LM FOR 99
COL RQ FOR 99
COL BL FOR 99
COL CTIME FOR 999999
SELECT OBJECT_NAME OBJ_NAME, OBJECT_TYPE OBJ_TYPE, USERNAME, SESSION_ID || ',' || SERIAL# "SID/SER", OSUSER, PROGRAM, L.TYPE TP, LMODE LM, REQUEST RQ, BLOCK BL, CTIME
FROM V$LOCKED_OBJECT V, DBA_OBJECTS O, V$LOCK L, V$SESSION S
WHERE S.SID=L.SID AND V.OBJECT_ID=O.OBJECT_ID AND L.ID1=O.OBJECT_ID AND L.SID=V.SESSION_ID AND OBJECT_NAME NOT LIKE '%TMP'
ORDER BY CTIME ASC;

--Blocking sessions:
SET LINES 300
SET PAGESIZE 200
SET LONG 1000
COL BLOCKING_SESSION FORMAT 99999
COL OSUSER FORMAT A10
COL PROCESS FORMAT 999999
COL USERNAME FORMAT A10
COL SID FORMAT 99999
COL SERIAL# FORMAT 99999
COL WAIT_CLASS FORMAT A20
COL SECONDS_IN_WAIT FORMAT 999999
COL PROGRAM FORMAT A50
COL STATUS FORMAT A10
SELECT BLOCKING_SESSION,OSUSER,PROCESS,USERNAME,SID,SERIAL#,WAIT_CLASS,SECONDS_IN_WAIT,PROGRAM,STATUS
FROM V$SESSION
WHERE BLOCKING_SESSION IS NOT NULL
ORDER BY BLOCKING_SESSION;

--Queries running for more than 60 seconds:
SET LINES 300
SET PAGESIZE 10000
SET LONG 10000
COL USERNAME FOR A20
COL SID FOR 999999
COL SER# FOR 999999
COL OSUSER FOR A15
COL SQL_TEXT FOR A220
SELECT S.USERNAME USERNAME,S.SID SID,S.SERIAL# AS SER#,S.OSUSER OSUSER,S.LAST_CALL_ET/60 MINS_RUNNING,Q.SQL_TEXT SQL_TEXT
FROM V$SESSION S JOIN V$SQLTEXT_WITH_NEWLINES Q ON S.SQL_ADDRESS = Q.ADDRESS
WHERE STATUS='ACTIVE' AND TYPE <>'BACKGROUND' AND LAST_CALL_ET> 60
ORDER BY SID,SERIAL#,Q.PIECE;

--Which query is waiting:
SELECT SID, SQL_TEXT
FROM V$SESSION S, V$SQL Q
WHERE SID IN (SELECT SID FROM V$SESSION WHERE STATE IN ('WAITING') AND WAIT_CLASS != 'IDLE' AND EVENT='ENQ: TX - ROW LOCK CONTENTION' AND (Q.SQL_ID = S.SQL_ID OR Q.SQL_ID = S.PREV_SQL_ID));

--Session Waits
SET LINESIZE 300
SET PAGESIZE 10000
SET LONG 10000
COL USERNAME FOR A25
COL MACHINE FOR A40
COL EVENT FOR A50
COL W_CLASS FOR A10
COL W_TIME FOR 999999
COL S_WAIT FOR 999999
SELECT NVL(S.USERNAME, '(ORACLE)') AS USERNAME, S.SID, S.SERIAL#, S.SQL_ID, S.MACHINE, SW.EVENT, SW.WAIT_CLASS AS W_CLASS, SW.WAIT_TIME AS W_TIME, SW.SECONDS_IN_WAIT AS S_WAIT, SW.STATE
FROM V$SESSION_WAIT SW, V$SESSION S
WHERE  S.SID = SW.SID AND SW.SECONDS_IN_WAIT > 0
ORDER BY S.SQL_ID,S.MACHINE,SW.SECONDS_IN_WAIT DESC;

--Running Queries (%)
SET LINES 300
SET PAGESIZE 100
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

--CHECK RUNNING JOBS
SELECT J.SID, J.LOG_USER, J.JOB,J.BROKEN, J.FAILURES, J.LAST_DATE||':'||J.LAST_SEC LAST_DATE, J.THIS_DATE||':'||J.THIS_SEC THIS_DATE, J.NEXT_DATE||':'||J.NEXT_SEC NEXT_DATE, J.NEXT_DATE - J.LAST_DATE INTERVAL, J.WHAT
FROM (SELECT DJR.SID, DJ.LOG_USER, DJ.JOB, DJ.BROKEN, DJ.FAILURES, DJ.LAST_DATE, DJ.LAST_SEC, DJ.THIS_DATE, DJ.THIS_SEC, DJ.NEXT_DATE, DJ.NEXT_SEC, DJ.INTERVAL, DJ.WHAT FROM DBA_JOBS DJ, DBA_JOBS_RUNNING DJR WHERE DJ.JOB = DJR.JOB) J;

--Find SQL by PID (01):
PROMPT "PLEASE ENTER THE UNIX PROCESS ID"
SET PAGESIZE 50000
SET LINESIZE 30000
SET LONG 500000
SET HEAD OFF
SELECT S.USERNAME SU, SUBSTR(SA.SQL_TEXT,1,540) TXT
FROM V$PROCESS P, V$SESSION S, V$SQLAREA SA
WHERE P.ADDR=S.PADDR AND S.USERNAME IS NOT NULL AND S.SQL_ADDRESS=SA.ADDRESS(+) AND S.SQL_HASH_VALUE=SA.HASH_VALUE(+) AND SPID=&SPID;

--Find SQL by PID (02):
SELECT SQL_TEXT
FROM V$SQL
WHERE SQL_ID = (SELECT SQL_ID FROM V$SESSION WHERE PADDR = (SELECT ADDR FROM V$PROCESS WHERE SPID = '&PROCESS_ID'));

--UNDO SPACE USAGE
COLUMN TABLESPACE FORMAT A20;
COLUMN SUM_IN_MB FORMAT 999999.99;
SELECT TABLESPACE_NAME TABLESPACE, STATUS, SUM(BYTES)/1024/1024 SUM_IN_MB, COUNT(*) COUNTS
FROM DBA_UNDO_EXTENTS
GROUP BY TABLESPACE_NAME, STATUS
ORDER BY 1,2;


SELECT EXECUTIONS, ROWS_PROCESSED, SQL_TEXT
FROM V$SQL
WHERE ROWS_PROCESSED > 10 AND UPPER(SQL_TEXT) NOT LIKE 'SELECT%' AND PARSING_USER_ID != 0 --IGNORE SYS AND COMMAND_TYPE != 47 --IGNORE PL/SQL
ORDER BY ROWS_PROCESSED DESC;
