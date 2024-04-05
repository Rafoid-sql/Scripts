-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
COL "TABLESPACE" FOR A30
COL "%FULL" FOR 999.99
SELECT TBM.TABLESPACE_NAME AS "TABLESPACE", ROUND(TBM.TABLESPACE_SIZE * TB.BLOCK_SIZE/(1024*1024*1024),2) AS "TOTAL(GB)", ROUND(TBM.USED_SPACE * TB.BLOCK_SIZE/(1024*1024*1024),2) AS "USED(GB)", ROUND((TBM.TABLESPACE_SIZE - TBM.USED_SPACE) * TB.BLOCK_SIZE/(1024*1024*1024),2) "FREE(GB)", TBM.USED_PERCENT AS "%FULL"
FROM DBA_TABLESPACE_USAGE_METRICS TBM
JOIN DBA_TABLESPACES TB ON TB.TABLESPACE_NAME = TBM.TABLESPACE_NAME
--WHERE TBM.TABLESPACE_NAME LIKE 'D1ME%'
ORDER BY "%FULL" ASC;
=========================================================================================================================================
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
=========================================================================================================================================
COL TABLESPACE FOR A30
COL TOTAL_MB FOR 999,999,999.99
COL USED_MB FOR 999,999,999,999.99
COL FREE_MB FOR 999,999,999.99
COL PCT_USED FOR 999.99
COL GRAPH FOR A22 HEADING "GRAPH (X=5%)"
COL STATUS FOR A10
COMPUTE SUM OF TOTAL_MB ON REPORT
COMPUTE SUM OF USED_MB ON REPORT
COMPUTE SUM OF FREE_MB ON REPORT
BREAK ON REPORT 
SELECT TOTAL.TS TABLESPACE, DECODE(TOTAL.MB,NULL,'OFFLINE',DBAT.STATUS) STATUS, TOTAL.MB TOTAL_MB, NVL(TOTAL.MB - FREE.MB,TOTAL.MB) USED_MB, NVL(FREE.MB,0) FREE_MB,  DECODE(TOTAL.MB,NULL,0,NVL(ROUND((TOTAL.MB - FREE.MB)/(TOTAL.MB)*100,2),100)) PCT_USED, CASE WHEN (TOTAL.MB IS NULL) THEN '['||RPAD(LPAD('OFFLINE',13,'-'),20,'-')||']' ELSE '['|| DECODE(FREE.MB, NULL,'XXXXXXXXXXXXXXXXXXXX', NVL(RPAD(LPAD('X',TRUNC((100-ROUND( (FREE.MB)/(TOTAL.MB) * 100, 2))/5),'X'),20,'-'), '--------------------'))||']' 
END AS GRAPH
FROM (SELECT TABLESPACE_NAME TS, SUM(BYTES)/1024/1024 MB FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) TOTAL, (SELECT TABLESPACE_NAME TS, SUM(BYTES)/1024/1024 MB FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) FREE, DBA_TABLESPACES DBAT
WHERE TOTAL.TS=FREE.TS(+) AND TOTAL.TS=DBAT.TABLESPACE_NAME
UNION ALL
SELECT SH.TABLESPACE_NAME, 'TEMP', SUM(SH.BYTES_USED+SH.BYTES_FREE)/1024/1024 TOTAL_MB, SUM(SH.BYTES_USED)/1024/1024 USED_MB, SUM(SH.BYTES_FREE)/1024/1024 FREE_MB, ROUND(SUM(SH.BYTES_USED)/SUM(SH.BYTES_USED+SH.BYTES_FREE)*100,2) PCT_USED, '['||DECODE(SUM(SH.BYTES_FREE),0,'XXXXXXXXXXXXXXXXXXXX', NVL(RPAD(LPAD('X',(TRUNC(ROUND((SUM(SH.BYTES_USED)/SUM(SH.BYTES_USED+SH.BYTES_FREE))*100,2)/5)),'X'),20,'-'), '--------------------'))||']'
FROM V$TEMP_SPACE_HEADER SH
GROUP BY TABLESPACE_NAME
ORDER BY 6;
=========================================================================================================================================
COL "TABLESPACE" FOR A40
COL "QTDE" FOR 9999
COL "TOTAL_GB" FOR 999999999999
COL "USADO_GB" FOR 999999999999
COL "% USADO" FOR 999.99
SELECT DECODE (GROUPING(TABLESPACE_NAME),1, 'XTOTAL DATAFILES',TABLESPACE_NAME) "TABLESPACE", COUNT(*) "QTDE", SUM(MAXBYTES/1048576) "TOTAL_GB", SUM(BYTES/1048576) "USADO_GB", TO_CHAR((SUM(BYTES/1048576)*100)/(SUM(MAXBYTES/1048576)+1),'999,99') ||'%' AS "% USADO"
FROM DBA_DATA_FILES
GROUP BY ROLLUP(TABLESPACE_NAME)
UNION ALL
SELECT DECODE (GROUPING(TABLESPACE_NAME),1, 'XTOTAL TEMPFILES',TABLESPACE_NAME) "TABLESPACE", COUNT(*) "QTDE", SUM(MAXBYTES/1048576) "TOTAL_GB", SUM(BYTES/1048576) "USADO_GB", TO_CHAR((SUM(BYTES/1048576)*100)/(SUM(MAXBYTES/1048576)+1),'999,99') ||'%' AS "% USADO"
FROM DBA_TEMP_FILES
GROUP BY ROLLUP(TABLESPACE_NAME)
ORDER BY 1 ASC;
=========================================================================================================================================
SELECT DF.TABLESPACE_NAME "TABLESPACE", (DF.ACTUALSPACE - FS.FREESPACE) "USED MB", FS.FREESPACE "F_ACT MB", DF.ACTUALSPACE "ACT MB", ROUND(100 * (FS.FREESPACE / DF.ACTUALSPACE)) "F_ACT %", (DF.ACTUALSPACE - DD.TOTALSPACE) "F_TOT MB", DD.TOTALSPACE "TOT MB"
--ROUND(100 * ((DD.TOTALSPACE - DF.ACTUALSPACE) / DD.TOTALSPACE)) "F_TOT %"
FROM (SELECT TABLESPACE_NAME, ROUND(SUM(BYTES) / 1048576) ACTUALSPACE FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) DF, (SELECT TABLESPACE_NAME, ROUND(SUM(BYTES) / 1048576) FREESPACE FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) FS, (select TABLESPACE_NAME, ROUND(SUM(MAXBYTES) / 1048576) TOTALSPACE FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) DD
WHERE DF.TABLESPACE_NAME = FS.TABLESPACE_NAME(+) AND DF.TABLESPACE_NAME = DD.TABLESPACE_NAME(+)
--AND DF.TABLESPACE_NAME = 'RUN_DATA'
--AND FS.TABLESPACE_NAME = 'RUN_DATA'
ORDER BY 1;
=========================================================================================================================================
SET SERVEROUTPUT ON
DECLARE
DBF NUMBER;
TMPDBF NUMBER;
LGF NUMBER;
CTL NUMBER;
SOMA NUMBER;
BEGIN
SELECT TRUNC(SUM(BYTES/1024/1024),2) INTO DBF FROM V$DATAFILE;
SELECT TRUNC(SUM(BYTES/1024/1024),2) INTO TMPDBF FROM V$TEMPFILE;
SELECT TRUNC(SUM(BYTES/1024/1024),2) INTO LGF FROM V$LOG L, V$LOGFILE LF WHERE L.GROUP# = LF.GROUP#;
SELECT TRUNC(SUM(BLOCK_SIZE*FILE_SIZE_BLKS/1024/1024),2) INTO CTL FROM V$CONTROLFILE;
SELECT TRUNC((DBF+TMPDBF+LGF+CTL)/1024,2) INTO SOMA FROM DUAL;
DBMS_OUTPUT.PUT_LINE(CHR(10));
DBMS_OUTPUT.PUT_LINE('DATAFILES: '|| DBF ||' MB');
DBMS_OUTPUT.PUT_LINE(CHR(0));
DBMS_OUTPUT.PUT_LINE('TEMPFILES: '|| TMPDBF ||' MB');
DBMS_OUTPUT.PUT_LINE(CHR(0));
DBMS_OUTPUT.PUT_LINE('LOGFILES: '|| LGF ||' MB');
DBMS_OUTPUT.PUT_LINE(CHR(0));
DBMS_OUTPUT.PUT_LINE('CONTROLFILES: '|| CTL ||' MB');
DBMS_OUTPUT.PUT_LINE(CHR(0));
DBMS_OUTPUT.PUT_LINE('TOTAL TAMANHO: '|| SOMA ||' GB');
END;
/
=========================================================================================================================================
-- Temporary Tablespace Sort Usage.
SET PAUSE ON
SET PAUSE 'PRESS RETURN TO CONTINUE'
SET PAGESIZE 60
SET LINESIZE 300

SELECT
   A.TABLESPACE_NAME TABLESPACE,
   D.MB_TOTAL,
   SUM (A.USED_BLOCKS * D.BLOCK_SIZE) / 1024 / 1024 MB_USED,
   D.MB_TOTAL - SUM (A.USED_BLOCKS * D.BLOCK_SIZE) / 1024 / 1024 MB_FREE
FROM
   V$SORT_SEGMENT A,
(
SELECT
   B.NAME,
   C.BLOCK_SIZE,
   SUM (C.BYTES) / 1024 / 1024 MB_TOTAL
FROM
   V$TABLESPACE B,
   V$TEMPFILE C
WHERE
   B.TS#= C.TS#
GROUP BY
   B.NAME,
   C.BLOCK_SIZE
) D
WHERE
   A.TABLESPACE_NAME = D.NAME
GROUP BY
   A.TABLESPACE_NAME,
   D.MB_TOTAL
/