--Count Tables last Operation with Timestamp:
COL OPTIONS FOR A30
COL OBJ_NAME FOR A40
SELECT DISTINCT P.OBJECT_NAME OBJ_NAME, P.OPERATION OPERATION, P.TIMESTAMP TIME, P.OPTIONS OPTIONS, COUNT(1) IDX_USG_CNT 
FROM DBA_HIST_SQL_PLAN P, DBA_HIST_SQLSTAT S 
WHERE P.OBJECT_OWNER = 'SVC_PRD_POSR_GERYON' 
AND P.OPERATION LIKE 'TABLE%' 
AND P.SQL_ID = S.SQL_ID 
AND P.TIMESTAMP = (SELECT MAX(TIMESTAMP) FROM DBA_HIST_SQL_PLAN WHERE OBJECT_OWNER = 'SVC_PRD_POSR_GERYON')
GROUP BY P.OBJECT_OWNER, P.OBJECT_NAME, P.OPERATION, P.TIMESTAMP, P.OPTIONS 
ORDER BY 3,2;
=========================================================================================================================================
--List Tables last Operation with Timestamp:
COL OBJ_NAME FOR A40
COL OWNERS FOR A30
COL OPERATION FOR a20
SELECT DISTINCT P.OBJECT_NAME OBJ_NAME, P.OBJECT_OWNER OWNERS, P.OPERATION OPERATION, P.TIMESTAMP TIME
FROM DBA_HIST_SQL_PLAN P, DBA_HIST_SQLSTAT S 
WHERE P.OBJECT_OWNER = 'SVC_PRD_POSR_GERYON' 
AND P.OPERATION LIKE 'TABLE%' 
AND P.SQL_ID = S.SQL_ID 
AND P.TIMESTAMP IN (SELECT TIMESTAMP FROM DBA_HIST_SQL_PLAN WHERE OBJECT_OWNER = 'SVC_PRD_POSR_GERYON' AND TIMESTAMP >= (SYSDATE-15))
--AND P.TIMESTAMP = (SELECT MAX(TIMESTAMP) FROM DBA_HIST_SQL_PLAN WHERE OBJECT_OWNER = 'SVC_PRD_POSR_GERYON')
--GROUP BY P.OBJECT_OWNER, P.OBJECT_NAME, P.OPERATION, P.TIMESTAMP, P.OPTIONS 
ORDER BY 3,2;
=========================================================================================================================================
--Check Tables last Operation:
COL OWNERS FOR A20
COL OPTIONS FOR A30
COL OBJ_NAME FOR A40
SELECT P.OBJECT_OWNER OWNERS, P.OBJECT_NAME OBJ_NAME, P.OPERATION OPERATION, P.OPTIONS OPTIONS, COUNT(1) IDX_USG_CNT 
FROM DBA_HIST_SQL_PLAN P, DBA_HIST_SQLSTAT S 
WHERE P.OBJECT_OWNER = '&USERNAME' 
AND P.OPERATION LIKE 'TABLE%' 
AND P.SQL_ID = S.SQL_ID 
GROUP BY P.OBJECT_OWNER, P.OBJECT_NAME, P.OPERATION, P.OPTIONS 
ORDER BY 1,2,3;````````````````````
=========================================================================================================================================
--Check Tables size:
SELECT SEGMENT_NAME,SEGMENT_TYPE, SUM(BYTES/1024/1024/1024) GB
FROM DBA_SEGMENTS
WHERE SEGMENT_NAME='UNRECONCILED_DISTRIBUTION_FACT' 
GROUP BY SEGMENT_NAME,SEGMENT_TYPE; 