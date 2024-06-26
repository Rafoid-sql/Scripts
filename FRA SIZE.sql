-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
SET LINES 100
COL NAME FORMAT A60
SELECT NAME, FLOOR(SPACE_LIMIT / 1024 / 1024) "SIZE MB", CEIL(SPACE_USED / 1024 / 1024) "USED MB"
FROM V$RECOVERY_FILE_DEST;
=========================================================================================================================================
-- FRA Occupants
SELECT * FROM V$FLASH_RECOVERY_AREA_USAGE;
=========================================================================================================================================
-- Location and size of the FRA
SHOW PARAMETER DB_RECOVERY_FILE_DEST
=========================================================================================================================================
-- Size, used, Reclaimable 
SELECT ROUND((A.SPACE_LIMIT / 1024 / 1024 / 1024), 2) AS FLASH_IN_GB, ROUND((A.SPACE_USED / 1024 / 1024 / 1024), 2) AS FLASH_USED_IN_GB, ROUND((A.SPACE_RECLAIMABLE / 1024 / 1024 / 1024), 2) AS FLASH_RECLAIMABLE_GB, SUM(B.PERCENT_SPACE_USED)  AS PERCENT_OF_SPACE_USED
FROM V$RECOVERY_FILE_DEST A, V$FLASH_RECOVERY_AREA_USAGE B
GROUP BY SPACE_LIMIT, SPACE_USED, SPACE_RECLAIMABLE;