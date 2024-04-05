SET LINES 200
SELECT SID, SERIAL#, CONTEXT, SOFAR, TOTALWORK, ROUND(SOFAR/TOTALWORK*100,2) "%COMPLETE", START_TIME,TIME_REMAINING,ELAPSED_SECONDS, SYSDATE + TIME_REMAINING/3600/24 END_AT
FROM V$SESSION_LONGOPS
WHERE OPNAME LIKE 'RMAN%'
AND OPNAME NOT LIKE '%AGGREGATE%'
AND TOTALWORK != 0
AND SOFAR <> TOTALWORK;