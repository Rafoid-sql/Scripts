-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 300
SET PAGESIZE 1000
SET LONG 10000
SET UNDERLINE =
=========================================================================================================================================
COL DB_LINK FORMAT A30
COL USERNAME FORMAT A20
COL HOST FORMAT A30
SELECT * FROM DBA_DB_LINKS;
=========================================================================================================================================
SET LINESIZE 500
SET PAGESIZE 1000
COL DB_LINK FOR A40
COL HOST FOR A20
SELECT OWNER, DB_LINK, USERNAME, HOST,
TO_CHAR(CREATED,’MM/DD/YYYY HH24:MI:SS’) CRIACAO
FROM DBA_DB_LINKS
ORDER BY OWNER, DB_LINK;