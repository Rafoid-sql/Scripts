--Data Guard - How To Check Whether Physical Standby is in Sync with the Primary or Not?

-----------------------------------------------------------------------------------------------
--Check for GAP on standby
-----------------------------------------------------------------------------------------------
-- primary + standby:
SELECT MAX(SEQUENCE#) FROM V$LOG_HISTORY;


-- primary:
SELECT THREAD# "Thread",SEQUENCE# "Last Sequence Generated" 
FROM V$ARCHIVED_LOG 
WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#) ORDER BY 1;


-- standby:
SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" 
FROM (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH, (SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY 
WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;


--IF GAP EXISTS
-----------------------------------------------------------------------------------------------
--Identify missing archive log files
-----------------------------------------------------------------------------------------------
-- standby:
SELECT THREAD#, LOW_SEQUENCE#, HIGH_SEQUENCE# FROM V$ARCHIVE_GAP;


-- primary:
SELECT NAME FROM V$ARCHIVED_LOG WHERE THREAD# = 1 AND DEST_ID = 1 AND SEQUENCE# BETWEEN 09464 AND 90468;


--Copy the above redo log files to the physical standby database and register them using 
--the ALTER DATABASE REGISTER LOGFILE ... SQL statement on the physical standby database.
-- standby:
ALTER DATABASE REGISTER LOGFILE '/u04/arch/HSBC33/arch_t1_s64.dbf';


-- standby:
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;


ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;