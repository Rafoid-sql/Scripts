-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
COL TYPE FORMAT A15
COL NAME FORMAT A90
COL FILE# FORMAT 9999999
COL MBYTES FORMAT 999999999
COL BLOCKS FORMAT 999999999
COL BLOCK_SIZE FORMAT 99999
SELECT 'datafile' AS TYPE, NAME, ROUND(BYTES/1048576,2) AS MBYTES, BLOCKS, BLOCK_SIZE FROM V$DATAFILE where NAME like LOWER('%&DATAFILE%')
UNION ALL
SELECT 'tempfile' AS TYPE, NAME, ROUND(BYTES/1048576,2) AS MBYTES, BLOCKS, BLOCK_SIZE FROM V$TEMPFILE
UNION ALL
SELECT 'controlfile' AS TYPE, NAME, ROUND((BLOCK_SIZE*FILE_SIZE_BLKS)/1048576,2) AS MBYTES, FILE_SIZE_BLKS, BLOCK_SIZE FROM V$CONTROLFILE
UNION ALL
SELECT 'logfile' AS TYPE, MEMBER, NULL, NULL, NULL FROM V$LOGFILE
ORDER BY 1,2 ASC;
=========================================================================================================================================
-- LIST DATAFILES
COL TYPE FOR A15
COL NAME FOR A60
COL MBYTES FOR 999999999
SELECT 'DATAFILE' AS TYPE, NAME, ROUND(BYTES/1048576,2) AS MBYTES FROM V$DATAFILE WHERE NAME LIKE LOWER('%&DATAFILE%');
COL TYPE FOR A15
COL NAME FOR A60
COL MBYTES FOR 999999999
SELECT 'DATAFILE' AS TYPE, NAME, ROUND(BYTES/1048576,2) AS MBYTES FROM V$DATAFILE WHERE NAME LIKE LOWER('%&DATAFILE%');
--SELECT 'DATAFILE' AS TYPE, 'ALTER DATABASE DATAFILE '''||NAME||''' RESIZE 32767M;' AS NAME, ROUND(BYTES/1048576,2) AS MBYTES FROM V$DATAFILE WHERE NAME LIKE LOWER('%&DATAFILE%');
=========================================================================================================================================
-- LIST TEMPFILES
COL NAME FOR A50
SELECT 'TEMPFILE' AS TYPE, NAME, ROUND(BYTES/1048576,2) AS MBYTES, BLOCKS, BLOCK_SIZE FROM V$TEMPFILE;
=========================================================================================================================================
SET LINESIZE 1000 PAGESIZE 0 FEEDBACK OFF TRIMSPOOL ON
WITH
-- GET HIGHEST BLOCK ID FROM EACH DATAFILES ( FROM X$KTFBUE AS WE DON'T NEED ALL JOINS FROM DBA_EXTENTS )
HWM AS (SELECT /*+ MATERIALIZE */ KTFBUESEGTSN TS#,KTFBUEFNO RELATIVE_FNO,MAX(KTFBUEBNO+KTFBUEBLKS-1) HWM_BLOCKS FROM SYS.X$KTFBUE GROUP BY KTFBUEFNO,KTFBUESEGTSN),
-- JOIN TS# WITH TABLESPACE_NAME
HWMTS AS (SELECT NAME TABLESPACE_NAME,RELATIVE_FNO,HWM_BLOCKS FROM HWM JOIN V$TABLESPACE USING(TS#)),
-- JOIN WITH DATAFILES, PUT 5M MINIMUM FOR DATAFILES WITH NO EXTENTS
HWMDF AS (SELECT FILE_NAME,NVL(HWM_BLOCKS*(BYTES/BLOCKS),5*1024*1024) HWM_BYTES,BYTES,AUTOEXTENSIBLE,MAXBYTES FROM HWMTS RIGHT JOIN DBA_DATA_FILES USING(TABLESPACE_NAME,RELATIVE_FNO))
SELECT
 CASE WHEN AUTOEXTENSIBLE='YES' AND MAXBYTES>=BYTES
 THEN -- WE GENERATE RESIZE STATEMENTS ONLY IF AUTOEXTENSIBLE CAN GROW BACK TO CURRENT SIZE
  '/* RECLAIM '||TO_CHAR(CEIL((BYTES-HWM_BYTES)/1024/1024),999999)
   ||'M FROM '||TO_CHAR(CEIL(BYTES/1024/1024),999999)||'M */ '
   ||'ALTER DATABASE DATAFILE '''||FILE_NAME||''' RESIZE '||CEIL(HWM_BYTES/1024/1024)||'M;'
 ELSE -- GENERATE ONLY A COMMENT WHEN AUTOEXTENSIBLE IS OFF
  '/* RECLAIM '||TO_CHAR(CEIL((BYTES-HWM_BYTES)/1024/1024),999999)
   ||'M FROM '||TO_CHAR(CEIL(BYTES/1024/1024),999999)
   ||'M AFTER SETTING AUTOEXTENSIBLE MAXSIZE HIGHER THAN CURRENT SIZE FOR FILE '
   || FILE_NAME||' */'
 END SQL
FROM HWMDF
WHERE BYTES-HWM_BYTES>1024*1024 -- RESIZE ONLY IF AT LEAST 1MB CAN BE RECLAIMED
ORDER BY BYTES-HWM_BYTES DESC;
/
=========================================================================================================================================
COL TYPE FORMAT A15
COL NAME FORMAT A90
COL FILE# FORMAT 9999999
COL MBYTES FORMAT 999999999
COL BLOCKS FORMAT 999999999
COL BLOCK_SIZE FORMAT 99999
SELECT 'datafile' AS TYPE, NAME FROM V$DATAFILE
UNION ALL
SELECT 'tempfile' AS TYPE, NAME FROM V$TEMPFILE
UNION ALL
SELECT 'controlfile' AS TYPE, NAME FROM V$CONTROLFILE
UNION ALL
SELECT 'logfile' AS TYPE, MEMBER FROM V$LOGFILE
ORDER BY 2,1 ASC;
=========================================================================================================================================
COL TYPE FORMAT A15
COL NAME FORMAT A90
COL FILE# FORMAT 9999999
COL MBYTES FORMAT 999999999
COL BLOCKS FORMAT 999999999
COL BLOCK_SIZE FORMAT 99999
SELECT 'DATAFILE' AS TYPE, NAME, ROUND(BYTES/1048576,2) AS MBYTES, BLOCKS, BLOCK_SIZE FROM V$DATAFILE WHERE NAME LIKE '%UNDO%';