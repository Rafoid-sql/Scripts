SELECT /*+ RULE */ D.JOB, V.SID, V.SERIAL#, LOG_USER USERNAME, WHAT,
DECODE(TRUNC(SYSDATE - LOGON_TIME), 0, NULL,
TRUNC(SYSDATE - LOGON_TIME) || ' Days' || ' + ') ||
TO_CHAR(TO_DATE(TRUNC(MOD(SYSDATE-LOGON_TIME,1) * 86400), 'SSSSS'), 'HH24:MI:SS') RUNNING,
D.FAILURES, 'alter system kill session ' || '''' || V.SID || ', ' || V.SERIAL# || '''' || ' immediate;' KILL_SQL
FROM DBA_JOBS_RUNNING D, V$SESSION V, DBA_JOBS J
WHERE V.SID = D.SID
AND D.JOB = J.JOB;

--Second login as the owner of the job and mark it BROKEN
BEGIN
 DBMS_JOB.BROKEN(JOB,TRUE);
END;
COMMIT;

--Third as sysdba kill the related session
ALTER SYSTEM KILL SESSION 'SID, SERIAL#' IMMEDIATE;