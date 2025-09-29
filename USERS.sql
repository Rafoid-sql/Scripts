-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 5000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
COL USERNAME FOR A20
COL ACCOUNT_STATUS FOR A20
COL PROFILE FOR A20
SELECT USERNAME,ACCOUNT_STATUS,PROFILE 
FROM DBA_USERS 
WHERE USERNAME IN ('RKEYSE01');
=========================================================================================================================================
-- PASSWORD CHANGE
COL HOST_NAME FOR A30
COL SYSTIMESTAMP FOR A40
COL USERNAME FOR A20
--:;,.~`!@%^&*()-+=<>?/'"|\[]{}$
SELECT INSTANCE_NAME,HOST_NAME,SYSTIMESTAMP FROM V$INSTANCE;
SELECT NAME,PTIME FROM USER$ WHERE NAME IN ('SAILPOINTWATSONADM ');

export TNS_ADMIN=/orasw/prman/app/oracle/common/scripts/useradmin
mkstore -wrl $TNS_ADMIN -listCredential
mkstore -wrl $TNS_ADMIN -modifyCredential ptesp system "<PASSWORD>"
=========================================================================================================================================
-- GET DDL FROM OBJECT
SELECT DBMS_METADATA.GET_DDL('OBJECT_TYPE','OBJECT_NAME','OWNER') FROM DUAL;
=========================================================================================================================================
--Check user history;
COLUMN db_name_col NEW_VALUE db_name
SELECT SYS_CONTEXT ('USERENV', 'DB_NAME') AS db_name_col FROM dual;
SPOOL  &db_name._&&user._details.log

COL USERNAME FOR A15
COL SAMPLE_TIME FOR A25
COL SQL_OPNAME FOR A15
COL PROGRAM FOR A25
COL MODULE FOR A20
COL MACHINE FOR A40
COL SQL_TEXT FOR A40
SELECT C.USERNAME, A.SAMPLE_TIME, A.SQL_OPNAME, A.PROGRAM, A.MODULE, A.MACHINE, B.SQL_TEXT
FROM DBA_HIST_ACTIVE_SESS_HISTORY A, DBA_HIST_SQLTEXT B, DBA_USERS C
WHERE A.SQL_ID = B.SQL_ID(+)
AND A.USER_ID=C.USER_ID
<<<<<<< Updated upstream
AND C.USERNAME = ('&&user')
AND A.SAMPLE_TIME = (SYSDATE - 15)
=======
--AND C.USERNAME = ('&&user')
AND A.SAMPLE_TIME = (SYSDATE - 180)
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
ORDER BY A.SAMPLE_TIME ASC;

SPOOL off;
UNDEFINE user;
=========================================================================================================================================
--Check user history II:
COL "OWNER" FOR A20
COL "OBJ_NAME" FOR A40
SELECT P.OBJECT_OWNER AS "OWNER", P.OBJECT_NAME AS "OBJ_NAME", P.OPERATION OPERATION, P.OPTIONS OPTIONS, COUNT(1) IDX_USG_CNT, O.TIMESTAMP as "DATE"
FROM DBA_HIST_SQL_PLAN P,DBA_HIST_SQLSTAT S, DBA_OBJECTS O
WHERE O.OBJECT_ID = P.OBJECT# 
--AND P.OBJECT_OWNER IN ('SSCOPE') 
--AND P.OBJECT_OWNER IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='N') 
AND P.OPERATION LIKE 'TABLE%' 
AND P.SQL_ID = S.SQL_ID 
GROUP BY P.OBJECT_OWNER,P.OBJECT_NAME,P.OPERATION,P.OPTIONS,O.TIMESTAMP 
ORDER BY 6 desc,1,2,3;
=========================================================================================================================================
--Check user history III:
COL USERNAME FOR A20
COL SAMPLE_TIME FOR A25
COL SQL_OPNAME FOR A15
COL PROGRAM FOR A50
COL MODULE FOR A40
COL MACHINE FOR A50
SELECT C.USERNAME, A.SAMPLE_TIME, A.SQL_OPNAME, A.PROGRAM, A.MODULE, A.MACHINE
FROM DBA_HIST_ACTIVE_SESS_HISTORY A, DBA_USERS C
WHERE A.USER_ID=C.USER_ID
AND A.SAMPLE_TIME >= TRUNC(SYSDATE) - 1
--AND A.SAMPLE_TIME >= TRUNC(SYSDATE) - 90
AND A.SAMPLE_TIME <= TRUNC(SYSDATE)
--AND C.USERNAME IN (SELECT USERNAME FROM DBA_USERS WHERE ORACLE_MAINTAINED='N')
AND C.USERNAME IN ('UDMF_UI')
ORDER BY A.SAMPLE_TIME DESC;
=========================================================================================================================================
--CHECK OBJECTS WITHIN OBJECTS:
COL FUNCTION_NAME FOR A40
COL FUNCTION TYPE FOR A15
COL REFERENCED_NAME FOR A40
COL REFERENCED_TYPE FOR A15
SELECT OWNER||'.'||NAME AS FUNCTION_NAME,TYPE AS FUNCTION_TYPE,REFERENCED_OWNER||'.'||REFERENCED_NAME AS REFERENCED_NAME,REFERENCED_TYPE
FROM DBA_DEPENDENCIES
WHERE TYPE = UPPER('&OBJECT_TYPE') 
AND NAME = UPPER('&OBJECT_NAME')
AND REFERENCED_OWNER = UPPER('&OWNER')
AND REFERENCED_OWNER NOT IN ('ANONYMOUS','CTXSYS','DBSNMP','EXFSYS','MDSYS','MGMT_VIEW','OLAPSYS','OWBSYS','ORDPLUGINS','ORDSYS','SI_INFORMTN_SCHEMA','SYS','SYSMAN','SYSTEM','TSMSYS','WK_TEST','WKPROXY','WMSYS','XDB','APEX_040000','APEX_PUBLIC_USER','DIP','FLOWS_30000','FLOWS_FILES','MDDATA','ORACLE_OCM','XS$NULL','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','PUBLIC','OUTLN','WKSYS','LBACSYS')
ORDER BY REFERENCED_NAME;
=========================================================================================================================================
--Check usernames:
SET DEFINE OFF
COL USERNAME FOR A20
COL ACCOUNT_STATUS FOR A20
SELECT USERNAME,ACCOUNT_STATUS,EXPIRY_DATE
FROM DBA_USERS
WHERE ACCOUNT_STATUS LIKE ('%LOCKED%');
WHERE ACCOUNT_STATUS NOT IN ('OPEN', 'EXPIRED & LOCKED');
=========================================================================================================================================
--Check Account LOCKED Dates:
COL "INST" FOR 99
COL "SESSION" FOR 999999999
COL DB_USER FOR A25
COL OS_USER FOR A20
COL OS_HOST FOR A35
COL OS_PROCESS FOR 999999999
COL EXTENDED_TIMESTAMP FOR A35
COL TERMINAL FOR A15
SELECT INST_ID AS "INST", SESSION_ID AS "SESSION", DB_USER, OS_USER, OS_HOST, OS_PROCESS, TERMINAL, RETURNCODE, EXTENDED_TIMESTAMP
FROM GV$XML_AUDIT_TRAIL
WHERE DB_USER='&&USER'
--AND RETURNCODE IN (1017,28000)  
AND EXTENDED_TIMESTAMP > (SYSTIMESTAMP-1)
--AND EXTENDED_TIMESTAMP > (SYSTIMESTAMP-1/24)
--AND EXTENDED_TIMESTAMP > (SYSTIMESTAMP-15/1440)
ORDER BY EXTENDED_TIMESTAMP ASC;

UNDEFINE USER;
=========================================================================================================================================
--Check Remaining LOCK time:
COL USERNAME FOR A30
SELECT username, account_status, lock_date, ROUND((SYSDATE - lock_date) * 1440, 2) AS minutes_locked, (SELECT limit * 1440 FROM dba_profiles WHERE profile = (SELECT profile FROM dba_users WHERE username = '&&USER') AND resource_name = 'PASSWORD_LOCK_TIME') - ROUND((SYSDATE - lock_date) * 1440, 2) AS minutes_remaining
FROM dba_users
WHERE username = '&&USER' AND account_status LIKE '%TIMED%';
=========================================================================================================================================
--Check username II (11g-):
COL USERNAME FOR A30
COL ACCOUNT_STATUS FOR A25
COL CREATED FOR A20
COL EXPIRY_DATE HEADING 'EXPIRED' FOR A20
COL LOCK_DATE HEADING 'LOCKED' FOR A20
COL PROFILE FOR A25
SELECT USERNAME, ACCOUNT_STATUS, CREATED, EXPIRY_DATE, LOCK_DATE, PROFILE FROM DBA_USERS WHERE USERNAME LIKE UPPER('%&USER%');
--SELECT USERNAME, ACCOUNT_STATUS, CREATED, EXPIRY_DATE, LOCK_DATE, PROFILE FROM DBA_USERS WHERE USERNAME IN ('KDS5395','NCABELL3');
=========================================================================================================================================
--Check username III (12c+):
COL USERNAME FOR A30
COL ACCOUNT_STATUS FOR A25
COL CREATED FOR A20
COL EXPIRY_DATE HEADING 'EXPIRED' FOR A20
COL LOCK_DATE HEADING 'LOCKED' FOR A20
COL PROFILE FOR A25
COL LAST_LOGIN FOR A40
--SELECT USERNAME, ACCOUNT_STATUS, CREATED, EXPIRY_DATE, LOCK_DATE, PROFILE, LAST_LOGIN FROM DBA_USERS WHERE USERNAME LIKE UPPER('&USER');
SELECT USERNAME, ACCOUNT_STATUS, CREATED, EXPIRY_DATE, LOCK_DATE, PROFILE FROM DBA_USERS WHERE USERNAME = UPPER('LHAMILTON');
=========================================================================================================================================
-- CHECK USERNAME LAST ACTIVITY:
COL EXTENDED_TIMESTAMP FOR A60
COL DB_USER  FOR A20
COL OS_USER   FOR A20
COL OS_HOST FOR A40
SELECT MAX(EXTENDED_TIMESTAMP) LAST_ACTIVITY
FROM GV$XML_AUDIT_TRAIL
WHERE DB_USER = '&USER'
ORDER BY EXTENDED_TIMESTAMP;
=========================================================================================================================================
--Check user last changed password:
COL NAME FOR A20
COL "LAST_CHANGED" FOR A15
COL "LAST_CHANGED_TIME" FOR A25
SELECT NAME, PTIME "LAST_CHANGED", TO_CHAR(PTIME,'DD-MM-YY HH24:MI:SS AM') "LAST_CHANGED_TIME" 
FROM SYS.USER$ WHERE NAME IN ('&USER');
=========================================================================================================================================
-- CHECK DENIED CONNECTIONS TO THE DATABASE:
SELECT INST_ID,SESSION_ID,EXTENDED_TIMESTAMP,DB_USER,OS_USER,OS_HOST
FROM V$XML_AUDIT_TRAIL;
WHERE RETURNCODE='1017'
AND DB_USER = '&DB_USER'
AND EXTENDED_TIMESTAMP >= SYSDATE-1
ORDER BY EXTENDED_TIMESTAMP;
=========================================================================================================================================
--Retrieve oracle password:
SELECT DBMS_METADATA.GET_DDL('USER', USERNAME) --|| '/' USERCREATE
FROM DBA_USERS
WHERE USERNAME IN ('DADOSADV','PRISMA','MERCANET');
=========================================================================================================================================
--Check users on v$session (RAC):
COL USERNAME FOR A30
COL OSUSER FOR A30
SELECT SID, SERIAL#, INST_ID, USERNAME, OSUSER, PROGRAM, STATUS, MACHINE
FROM GV$SESSION
--WHERE USERNAME = ('SVC_PRD_CDES_TABLEAU')
--WHERE SID IN (1254,1253)
ORDER BY 1;
=========================================================================================================================================
--Check users on v$session (SI):
COL USERNAME FOR A30
COL OSUSER FOR A30
SELECT SID, SERIAL#, USERNAME, OSUSER, PROGRAM, STATUS, MACHINE
FROM V$SESSION
--WHERE USERNAME IN ('ADM_USER')
--WHERE SID IN (1254,1253)
ORDER BY 1;

SELECT 'ALTER SYSTEM KILL SESSION '''||SID||','||SERIAL#||',@'||INST_ID||''' IMMEDIATE;'
FROM GV$SESSION
WHERE SID IN (3531, 626)
ORDER BY 1;

SET LINES 300 PAGESIZE 1000
COL USERNAME FOR A30
COL OSUSER FOR A20
COL OBJECT_NAME FOR A30
COL OWNER FOR A20
COL MACHINE FOR A20
SELECT C.OWNER,C.OBJECT_NAME,C.OBJECT_TYPE,B.SID,B.SERIAL#,B.INST_ID,B.STATUS,B.OSUSER,B.MACHINE,A.OBJECT_ID
FROM GV$LOCKED_OBJECT A,GV$SESSION B,DBA_OBJECTS C
WHERE B.SID = A.SESSION_ID
AND A.OBJECT_ID = C.OBJECT_ID 
--AND C.OBJECT_NAME IN ('SDP_USAGE_THRESHOLD')
AND B.SID IN (3531, 626)
ORDER BY SID;
=========================================================================================================================================
--CHECK LOGON TIMES
COL INACTIVE_SESSIONS FOR A50
COL USERNAME FOR A35
SET LINES 230 PAGES 100
BREAK ON USERNAME
SELECT USERNAME, CASE WHEN LAST_CALL_ET > 28800 THEN 'MORE THAN 480 MINUTES (8HS)' ELSE
       CASE WHEN LAST_CALL_ET > 14400 THEN 'MORE THAN 240 MINUTES (4HS)' ELSE
       CASE WHEN LAST_CALL_ET >  7200 THEN 'MORE THAN 120 MINUTES (2HS)' ELSE
       CASE WHEN LAST_CALL_ET >  3600 THEN 'MORE THAN 060 MINUTES (1HS)' ELSE
       CASE WHEN LAST_CALL_ET >  1800 THEN 'MORE THAN 030 MINUTES' ELSE
       CASE WHEN LAST_CALL_ET >   600 THEN 'MORE THAN 010 MINUTES' END END END END END END AS INACTIVE_SESSIONS, COUNT(*) QTY
FROM GV$SESSION
WHERE STATUS = 'INACTIVE'
AND LAST_CALL_ET > 600 
AND TYPE='USER' /*AND USERNAME='SVC_PRD_EDGE_USER13'*/
GROUP BY USERNAME, CASE WHEN LAST_CALL_ET > 28800 THEN 'MORE THAN 480 MINUTES (8HS)' ELSE
       CASE WHEN LAST_CALL_ET > 14400 THEN 'MORE THAN 240 MINUTES (4HS)' ELSE
       CASE WHEN LAST_CALL_ET >  7200 THEN 'MORE THAN 120 MINUTES (2HS)' ELSE
       CASE WHEN LAST_CALL_ET >  3600 THEN 'MORE THAN 060 MINUTES (1HS)' ELSE
       CASE WHEN LAST_CALL_ET >  1800 THEN 'MORE THAN 030 MINUTES' ELSE
       CASE WHEN LAST_CALL_ET >   600 THEN 'MORE THAN 010 MINUTES' END END END END END END
ORDER BY 1,2;  
=========================================================================================================================================
--CHECK LOGON TIMESTAMP
SELECT TO_CHAR(LOGON_TIME,'YYYYMMDD_HH24MI') LOGIN_TIME,COUNT(1) QTY 
FROM GV$SESSION 
WHERE TYPE='USER'
--AND USERNAME='DFS_ADMIN'
GROUP BY TO_CHAR(LOGON_TIME,'YYYYMMDD_HH24MI') 
ORDER BY 1;
=========================================================================================================================================
--CHECK LOGON DETAILS
SELECT TO_CHAR(EVENT_TIMESTAMP,'DD-MON-YYYY HH24') AS LOG_DATE_HOUR_INTERVAL, USERHOST, OS_USERNAME, DBUSERNAME, ACTION_NAME, SUBSTR(AUTHENTICATION_TYPE, INSTR(AUTHENTICATION_TYPE, 'HOST')+5, INSTR(AUTHENTICATION_TYPE, 'PORT') - INSTR(AUTHENTICATION_TYPE, 'HOST')-7) AS HOST, CASE WHEN RETURN_CODE = 0 THEN 'SUCCESSFUL' ELSE CASE WHEN RETURN_CODE > 0 THEN 'FAILED' END END AS STATUS,COUNT(*) FROM UNIFIED_AUDIT_TRAIL
WHERE EVENT_TIMESTAMP >= TO_DATE('30-JAN-2023 00','DD-MON-YYYY HH24') AND DBUSERNAME NOT IN ('SYS','OPS$ORACLE') AND ACTION_NAME IN ('LOGOFF','LOGON','LOGOFF BY CLEANUP')
GROUP BY TO_CHAR(EVENT_TIMESTAMP,'DD-MON-YYYY HH24'), ACTION_NAME, CASE WHEN RETURN_CODE = 0 THEN 'SUCCESSFUL' ELSE CASE WHEN RETURN_CODE > 0 THEN 'FAILED' END END, USERHOST, SUBSTR(AUTHENTICATION_TYPE, INSTR(AUTHENTICATION_TYPE, 'HOST')+5, INSTR(AUTHENTICATION_TYPE, 'PORT') - INSTR(AUTHENTICATION_TYPE, 'HOST')-7), OS_USERNAME, DBUSERNAME
HAVING COUNT(*) >= 50
ORDER BY 1,2,4;
=========================================================================================================================================
--# PASSWORD Change History
SELECT DISTINCT USER$.NAME,USER$.PASSWORD PWD_HASH_NUMBER,USER$.PTIME LAST_UPDATE,USER_HISTORY$.PASSWORD_DATE PWD_CHG_DATE FROM SYS.USER_HISTORY$, SYS.USER$ WHERE USER_HISTORY$.USER# = USER$.USER#
AND USER$.NAME IN(SELECT USERNAME FROM DBA_USERS WHERE USERNAME IN ('&USER')) ORDER BY USER_HISTORY$.PASSWORD_DATE;
=========================================================================================================================================
--Check all users:
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
FROM VG$SESSION B, VG$PROCESS A
WHERE B.PADDR = A.ADDR
AND TYPE='USER'
--AND B.PROGRAM LIKE ('%rman%')
--AND CLIENT_INFO LIKE ('%69237192%')
AND SID IN (3722, 3923)
--AND MACHINE IN ('HMRT\SERVER_DELL')
--AND STATUS IN ('KILLED')
ORDER BY SID;
=========================================================================================================================================
--Check users on RAC:
COL USERNAME FOR A30
COL EVENT FOR A30
COL MACHINE FOR A20
COL OSUSER FOR A20
SELECT INST_ID, SID, SERIAL#, OSUSER, USERNAME, EVENT, MACHINE, LOCKWAIT, STATUS
FROM GV$SESSION
WHERE TYPE <>'BACKGROUND'
AND SID='546'
--AND STATUS = 'ACTIVE'
--AND OSUSER LIKE '%F08135%'
;
=========================================================================================================================================
--Check sessions RAC:
SELECT COUNT(*), INST_ID
FROM GV$SESSION
WHERE TYPE='USER'
GROUP BY INST_ID;

=========================================================================================================================================
-- CHECK SCHEMA SIZE BY OBJECT I
select sum(bytes)/1024/1024/1024 as size_in_GB, segment_type
from dba_segments
where owner='CAIN2' and segment_name like '%_ARCHIVE'
group by segment_type;
=========================================================================================================================================
-- CHECK SCHEMA SIZE BY OBJECT II
select sum(bytes)/1024/1024/1024 as size_in_GB, segment_type
from dba_segments
where owner='CAIN2'
group by segment_type;
=========================================================================================================================================

select c.username,a.SAMPLE_TIME, a.SQL_OPNAME, a.SQL_EXEC_START, a.program, a.module, a.machine,
b.SQL_TEXT
from DBA_HIST_ACTIVE_SESS_HISTORY a, dba_hist_sqltext b, dba_users c
where a.SQL_ID = b.SQL_ID(+)
and a.user_id=c.user_id
and c.username not in ('SYS','SYSTEM','DBSNMP')
and a.SAMPLE_TIME>='01-OCT-22'
order by a.SQL_EXEC_START asc;



set lines 300
col USERNAME for a30
col SAMPLE_TIME for a40
col SQL_OPNAME for a20
col program for a60
select c.username,a.SAMPLE_TIME, a.SQL_OPNAME, a.program
from DBA_HIST_ACTIVE_SESS_HISTORY a, dba_hist_sqltext b, dba_users c
where a.SQL_ID = b.SQL_ID(+)
and a.user_id=c.user_id
and c.username not in ('SYS','SYSTEM','DBSNMP')
and a.SAMPLE_TIME>='01-OCT-22'
order by a.SQL_EXEC_START asc;

=========================================================================================================================================
=========================================================================================================================================
=========================================================================================================================================

SET LINES 280 PAGESIZE 10000
COL OWNER FOR A20
COL "TABLE" FOR 99999
SELECT OWNER, COUNT(OWNER) AS "TABLE" 
FROM DBA_OBJECTS 
WHERE OWNER IN ('BBURTON7','JLAWLIS1','SRAUCH','AZOLOTO1') AND OBJECT_TYPE='TABLE' 
GROUP BY OWNER;


SET LINES 280 PAGESIZE 10000
COL OWNER FOR A20
COL "TABLE" FOR A50
SELECT OWNER, TABLE_NAME AS "TABLE"
FROM DBA_TABLES
WHERE OWNER IN ('BBURTON7','JLAWLIS1','SRAUCH','AZOLOTO1')
ORDER BY 1,2;


SET LINES 280 PAGESIZE 10000
COL "OWNER" FOR A20
COL "OBJ_NAME" FOR A40
SELECT P.OBJECT_OWNER AS "OWNER", P.OBJECT_NAME AS "OBJ_NAME", P.OPERATION OPERATION, P.OPTIONS OPTIONS, COUNT(1) IDX_USG_CNT, O.TIMESTAMP as "DATE"
FROM DBA_HIST_SQL_PLAN P,DBA_HIST_SQLSTAT S, DBA_OBJECTS O
WHERE O.OBJECT_ID = P.OBJECT# 
--AND P.OBJECT_OWNER IN ('BBURTON7','JLAWLIS1','SRAUCH','AZOLOTO1') 
--AND P.OPERATION LIKE 'TABLE%' 
AND P.SQL_ID = S.SQL_ID 
GROUP BY P.OBJECT_OWNER,P.OBJECT_NAME,P.OPERATION,P.OPTIONS,O.TIMESTAMP 
ORDER BY 6,1,2,3;


SET LINES 300 PAGESIZE 1000
COL USERNAME FOR A20
SELECT C.USERNAME, A.SAMPLE_TIME, A.SQL_OPNAME, A.SQL_EXEC_START, A.PROGRAM, A.MODULE, A.MACHINE, B.SQL_TEXT
FROM DBA_HIST_ACTIVE_SESS_HISTORY A, DBA_HIST_SQLTEXT B, DBA_USERS C
WHERE A.SQL_ID = B.SQL_ID(+)
AND A.USER_ID=C.USER_ID
ORDER BY A.SQL_EXEC_START ASC;




COLUMN db_name_col NEW_VALUE db_name
SELECT SYS_CONTEXT ('USERENV', 'DB_NAME') AS db_name_col FROM dual;
SPOOL  &db_name._&&user._details.log

SET LINES 300 PAGESIZE 1000
COL USERNAME FOR A15
COL SAMPLE_TIME FOR A25
COL SQL_OPNAME FOR A15
COL PROGRAM FOR A25
COL MODULE FOR A20
COL MACHINE FOR A40
COL SQL_TEXT FOR A40
SELECT C.USERNAME, A.SAMPLE_TIME, A.SQL_OPNAME, A.PROGRAM, A.MODULE, A.MACHINE, B.SQL_TEXT
FROM DBA_HIST_ACTIVE_SESS_HISTORY A, DBA_HIST_SQLTEXT B, DBA_USERS C
WHERE A.SQL_ID = B.SQL_ID(+)
AND A.USER_ID=C.USER_ID
AND C.USERNAME = ('&&user')
ORDER BY A.SAMPLE_TIME ASC;

SPOOL off;
UNDEFINE user;

SELECT distinct C.USERNAME
FROM DBA_HIST_ACTIVE_SESS_HISTORY A, DBA_USERS C
WHERE A.USER_ID=C.USER_ID;