-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 300 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
-- GENERATE FILE TO AUDIT ALL TABLES
set lines 500 pages 9999 echo on time on timing on trimspool on
alter session set nls_date_format = 'mm-dd-yyyy hh24:mi:ss';
spool enable_auditing_all_app_tables_CR004015975.sql
select sysdate from dual;
select 'audit select, update, delete, insert on '||owner||'.'||table_name||' by access;' from dba_tables where owner not in
('SYS', 'SYSTEM', 'WMSYS', 'SYSMAN','MDSYS','ORDSYS','XDB', 'WKSYS', 'EXFSYS','OLAPSYS', 'DBSNMP', 'DMSYS','CTXSYS','WK_TEST', 'ORDPLUGINS',
'OUTLN','DATAPOINT_AUDIT','XS$NULL','APPQOSSYS','ORACLE_OCM','ORDDATA','OWBSYS','OWBSYS_AUDIT','DATAPOINT','DATAPOINT_EM', 'DBTUNE','SYSREAD','GGSADM')
order by owner, table_name;
spool off;
=========================================================================================================================================
--CHECK AUDIT_TRAIL INFO
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
=========================================================================================================================================
COL USERNAME FOR A20
SELECT * FROM DATAPOINT_AUDIT.SPRINT_USER_LAST_LOGON 
WHERE USERNAME NOT IN ('SYS', 'SYSTEM', 'WMSYS', 'SYSMAN', 'MDSYS', 'ORDSYS', 'XDB', 'WKSYS', 'EXFSYS', 'OLAPSYS', 'DBSNMP', 'DMSYS', 'CTXSYS', 'WK_TEST', 'ORDPLUGINS', 'OUTLN', 'DATAPOINT_AUDIT', 'XS$NULL', 'APPQOSSYS', 'ORACLE_OCM', 'ORDDATA', 'OWBSYS', 'OWBSYS_AUDIT', 'DATAPOINT', 'DATAPOINT_EM', 'DBTUNE', 'SYSREAD', 'GGSADM') 
AND LAST_LOGON_TIME >= (SELECT SYSDATE-7 FROM DUAL) 
ORDER BY LAST_LOGON_TIME;
=========================================================================================================================================
COL HOST FOR A10
COL OWNER FOR A10
COL OBJ_NAME FOR A30
COL ACTION_NAME FOR A15
SELECT USERNAME, REPLACE(USERHOST,'.corp.sprint.com','') HOST, TIMESTAMP, OWNER, OBJ_NAME, ACTION_NAME FROM DBA_AUDIT_OBJECT 
WHERE USERNAME NOT IN ('SYS', 'SYSTEM', 'WMSYS', 'SYSMAN', 'MDSYS', 'ORDSYS', 'XDB', 'WKSYS', 'EXFSYS', 'OLAPSYS', 'DBSNMP', 'DMSYS', 'CTXSYS', 'WK_TEST', 'ORDPLUGINS', 'OUTLN', 'DATAPOINT_AUDIT', 'XS$NULL', 'APPQOSSYS', 'ORACLE_OCM', 'ORDDATA', 'OWBSYS', 'OWBSYS_AUDIT', 'DATAPOINT', 'DATAPOINT_EM', 'DBTUNE', 'SYSREAD', 'GGSADM') 
AND TIMESTAMP >= (SELECT SYSDATE-7 FROM DUAL) 
ORDER BY TIMESTAMP;
=========================================================================================================================================
SELECT ACTION_NAME, COUNT(ACTION_NAME) QTY FROM DBA_AUDIT_OBJECT 
WHERE USERNAME NOT IN ('SYS', 'SYSTEM', 'WMSYS', 'SYSMAN', 'MDSYS', 'ORDSYS', 'XDB', 'WKSYS', 'EXFSYS', 'OLAPSYS', 'DBSNMP', 'DMSYS', 'CTXSYS', 'WK_TEST', 'ORDPLUGINS', 'OUTLN', 'DATAPOINT_AUDIT', 'XS$NULL', 'APPQOSSYS', 'ORACLE_OCM', 'ORDDATA', 'OWBSYS', 'OWBSYS_AUDIT', 'DATAPOINT', 'DATAPOINT_EM', 'DBTUNE', 'SYSREAD', 'GGSADM') 
AND TIMESTAMP >= (SELECT SYSDATE-7 FROM DUAL)
GROUP BY ACTION_NAME
ORDER BY QTY;
=========================================================================================================================================
SELECT USERNAME, COUNT(USERNAME) QTY FROM DBA_AUDIT_OBJECT 
WHERE USERNAME NOT IN ('SYS', 'SYSTEM', 'WMSYS', 'SYSMAN', 'MDSYS', 'ORDSYS', 'XDB', 'WKSYS', 'EXFSYS', 'OLAPSYS', 'DBSNMP', 'DMSYS', 'CTXSYS', 'WK_TEST', 'ORDPLUGINS', 'OUTLN', 'DATAPOINT_AUDIT', 'XS$NULL', 'APPQOSSYS', 'ORACLE_OCM', 'ORDDATA', 'OWBSYS', 'OWBSYS_AUDIT', 'DATAPOINT', 'DATAPOINT_EM', 'DBTUNE', 'SYSREAD', 'GGSADM') 
AND TIMESTAMP >= (SELECT SYSDATE-7 FROM DUAL)
GROUP BY USERNAME
ORDER BY QTY;
=========================================================================================================================================
SELECT USERNAME, ACTION_NAME, COUNT(ACTION_NAME) QTY FROM DBA_AUDIT_OBJECT 
WHERE USERNAME NOT IN ('SYS', 'SYSTEM', 'WMSYS', 'SYSMAN', 'MDSYS', 'ORDSYS', 'XDB', 'WKSYS', 'EXFSYS', 'OLAPSYS', 'DBSNMP', 'DMSYS', 'CTXSYS', 'WK_TEST', 'ORDPLUGINS', 'OUTLN', 'DATAPOINT_AUDIT', 'XS$NULL', 'APPQOSSYS', 'ORACLE_OCM', 'ORDDATA', 'OWBSYS', 'OWBSYS_AUDIT', 'DATAPOINT', 'DATAPOINT_EM', 'DBTUNE', 'SYSREAD', 'GGSADM') 
AND TIMESTAMP >= (SELECT SYSDATE-7 FROM DUAL)
GROUP BY USERNAME,ACTION_NAME
ORDER BY QTY;