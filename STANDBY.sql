-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
--Primary:
EDIT DATABASE 'DGIPRD1B' SET STATE=TRANSPORT-OFF;
EDIT DATABASE 'DGIPRD1B' SET STATE=TRANSPORT-ON;

--Standby:
EDIT DATABASE 'CAINTTSTBY' SET STATE='APPLY-OFF';
EDIT DATABASE 'CAINTTSTBY' SET STATE='APPLY-ON';
=========================================================================================================================================
--CHECK DATAGUARD APPLY LAG
SELECT LOG_ARCHIVED-LOG_APPLIED "LOG_GAP", LOG_ARCHIVED, LOG_APPLIED  FROM 
(SELECT MAX(SEQUENCE#) LOG_ARCHIVED FROM GV$ARCHIVED_LOG WHERE DEST_ID=1 AND ARCHIVED='YES'),
(SELECT MAX(SEQUENCE#) LOG_APPLIED FROM GV$ARCHIVED_LOG WHERE DEST_ID=2 AND APPLIED='YES');
=========================================================================================================================================
--CHECK DATAGUARD APPLY LAG II
SELECT AL.THRD "THREAD", ALMAX "LAST SEQ RECEIVED", LHMAX "LAST SEQ APPLIED", (ALMAX-LHMAX) "DIFFERENCE" FROM 
(SELECT THREAD# THRD, MAX(SEQUENCE#) ALMAX FROM V$ARCHIVED_LOG WHERE RESETLOGS_CHANGE#=(SELECT RESETLOGS_CHANGE# 
FROM V$DATABASE) GROUP BY THREAD#) AL, (SELECT THREAD# THRD, MAX(SEQUENCE#) LHMAX FROM V$LOG_HISTORY
WHERE RESETLOGS_CHANGE#=(SELECT RESETLOGS_CHANGE# FROM V$DATABASE) GROUP BY THREAD#) LH WHERE AL.THRD = LH.THRD;
=========================================================================================================================================
--CHECK DATAGUARD APPLY LAG III
SELECT NAME, VALUE, DATUM_TIME,TIME_COMPUTED FROM V$DATAGUARD_STATS WHERE NAME LIKE 'apply lag';
=========================================================================================================================================
--CHECK APPLY LAG HISTOGRAM
SELECT * FROM V$STANDBY_EVENT_HISTOGRAM WHERE NAME = 'apply lag' AND COUNT > 0;
=========================================================================================================================================
--CHECK APPLIED ARCHIVES
SELECT DISTINCT THREAD#, SEQUENCE#, COMPLETION_TIME, FIRST_TIME, NEXT_TIME, APPLIED 
FROM GV$ARCHIVED_LOG 
ORDER BY COMPLETION_TIME DESC
FETCH FIRST 20 ROWS ONLY;
=========================================================================================================================================
--CHECK APPLIED ARCHIVES II
COL STATUS FOR A15
SELECT INST_ID, PROCESS, STATUS, RESETLOG_ID, THREAD#, SEQUENCE#, BLOCK#, BLOCKS 
FROM GV$MANAGED_STANDBY 
ORDER BY  INST_ID, PROCESS, STATUS, RESETLOG_ID, THREAD#, SEQUENCE#, BLOCK#, BLOCKS;
=========================================================================================================================================
--CHECK APPLIED ARCHIVES III
SET FEEDBACK ON
SELECT ARCHIVED_THREAD#, ARCHIVED_SEQ#, APPLIED_THREAD#, APPLIED_SEQ#
FROM GV$ARCHIVE_DEST_STATUS;
=========================================================================================================================================
--CHECK MRP0
SELECT PROCESS, THREAD#, SEQUENCE#, STATUS FROM GV$MANAGED_STANDBY WHERE PROCESS='MRP0';
=========================================================================================================================================
--CHECK PROCESSES STATUS
SELECT INST_ID,PROCESS,STATUS,CLIENT_PROCESS,SEQUENCE# FROM GV$MANAGED_STANDBY;
=========================================================================================================================================
SELECT 
(SELECT DB_UNIQUE_NAME FROM V$DATABASE) AS DB_UNIQUE_NAME, P.THREAD#, P.DEST_ID AS PRIMARY_DEST_ID, D.DEST_ID AS STANDBY_DEST_ID, PRIMARY_ARCHIVED_SEQUENCE, STANDBY_APPLIED_SEQUENCE, PRIMARY_ARCHIVED_SEQUENCE - STANDBY_APPLIED_SEQUENCE AS GAP
FROM 
(SELECT   DEST_ID, THREAD#, MAX (SEQUENCE#) AS PRIMARY_ARCHIVED_SEQUENCE FROM GV$ARCHIVED_LOG WHERE STANDBY_DEST = 'NO' GROUP BY DEST_ID, THREAD#) P,
(SELECT   DEST_ID, THREAD#, MAX (SEQUENCE#) AS STANDBY_APPLIED_SEQUENCE FROM GV$ARCHIVED_LOG WHERE STANDBY_DEST = 'YES' AND APPLIED = 'YES' GROUP BY DEST_ID, THREAD#) D
WHERE 
P.THREAD# = D.THREAD#
AND P.DEST_ID IN (SELECT SUBSTR (NAME, -1, 1) FROM V$PARAMETER WHERE NAME LIKE 'LOG_ARCHIVE_DEST_%' AND NAME NOT LIKE '%STATE%' AND VALUE IS NOT NULL)
AND D.DEST_ID IN (SELECT SUBSTR (NAME, -1, 1) FROM V$PARAMETER WHERE NAME LIKE 'LOG_ARCHIVE_DEST_%' AND NAME NOT LIKE '%STATE%' AND VALUE IS NOT NULL)
ORDER BY DB_UNIQUE_NAME, P.THREAD#, D.DEST_ID;
=========================================================================================================================================
--REDOLOGS STATUS
COLUMN REDOLOG_FILE_NAME FORMAT A50
SELECT
 A.GROUP#,
 A.THREAD#,
 A.SEQUENCE#,
 A.ARCHIVED,
 A.STATUS,
 B.MEMBER AS REDOLOG_FILE_NAME,
 (A.BYTES/1024/1024) AS SIZE_MB
FROM V$LOG A
JOIN V$LOGFILE B ON A.GROUP#=B.GROUP#
ORDER BY A.GROUP#;
=========================================================================================================================================
--FIX STANDBY ISSUES WITH ARCHIVES NOT BEING DELETED
SELECT * FROM V$ARCHIVE_DEST WHERE (VALID_NOW = 'UNKNOWN' AND STATUS = 'DEFERRED') ;
=========================================================================================================================================
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION PARALLEL 8;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION PARALLEL 16;