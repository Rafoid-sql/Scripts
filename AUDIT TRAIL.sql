SET LINES 300
SET PAGESIZE 1000
COL OS_USERNAME FOR A20
COL USERNAME FOR A20
COL TERMINAL FOR A20
COL TIMESTAMP FOR A10
COL ACTION FOR 999999
COL ACTION_NAME FOR A20
COL OBJ_NAME FOR A40
SELECT OS_USERNAME,USERNAME,TERMINAL,TIMESTAMP,ACTION,ACTION_NAME,OBJ_NAME FROM DBA_AUDIT_TRAIL 
WHERE TIMESTAMP BETWEEN TO_DATE('2020-06-15','YYYY-MM-DD') AND TO_DATE('2020-06-17','YYYY-MM-DD')
AND ACTION IN (7,6) --,2,12
AND OS_USERNAME LIKE 'SOLUS%'
ORDER BY TIMESTAMP,ACTION;