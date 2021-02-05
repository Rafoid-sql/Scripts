http://www.petefinnigan.com/weblog/archives/00001406.htm
https://dbaclass.com/article/purge-aud-table-using-dbms_audit_mgmt/

https://www.dbarj.com.br/2013/05/alterando-tablespace-de-audit-e-criando-uma-politica-de-expurgo-no-oracle-11g/


SELECT OWNER,
SEGMENT_NAME,
TABLESPACE_NAME
FROM   DBA_SEGMENTS
WHERE  SEGMENT_NAME IN ('AUD$', 'FGA_LOG$');



SET SERVEROUTPUT ON
BEGIN
IF sys.DBMS_AUDIT_MGMT.is_cleanup_initialized(sys.DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD) THEN
DBMS_OUTPUT.put_line('YES');
ELSE
DBMS_OUTPUT.put_line('NO');
END IF;
END;
/

NO
 
col PARAMETER_NAME for a60
col PARAMETER_VALUE for a30
col AUDIT_TRAIL for a20
SELECT PARAMETER_NAME, PARAMETER_VALUE, AUDIT_TRAIL  FROM DBA_AUDIT_MGMT_CONFIG_PARAMS;
 
PARAMETER_NAME                                               PARAMETER_VALUE                AUDIT_TRAIL
------------------------------------------------------------ ------------------------------ ----------------------------------------
AUDIT FILE MAX SIZE                                          10000                          OS AUDIT TRAIL
AUDIT FILE MAX SIZE                                          10000                          XML AUDIT TRAIL
AUDIT FILE MAX AGE                                           5                              OS AUDIT TRAIL
AUDIT FILE MAX AGE                                           5                              XML AUDIT TRAIL
DB AUDIT TABLESPACE                                          SYSAUX                         STANDARD AUDIT TRAIL
DB AUDIT TABLESPACE                                          SYSAUX                         FGA AUDIT TRAIL
DB AUDIT CLEAN BATCH SIZE                                    10000                          STANDARD AUDIT TRAIL
DB AUDIT CLEAN BATCH SIZE                                    10000                          FGA AUDIT TRAIL
OS FILE CLEAN BATCH SIZE                                     1000                           OS AUDIT TRAIL
OS FILE CLEAN BATCH SIZE                                     1000                           XML AUDIT TRAIL
 
10 rows selected



BEGIN
SYS.dbms_audit_mgmt.init_cleanup(
audit_trail_type         => SYS.DBMS_AUDIT_MGMT.AUDIT_TRAIL_DB_STD,
default_cleanup_interval => 72);
END;
/


SET SERVEROUTPUT ON
BEGIN
IF sys.DBMS_AUDIT_MGMT.is_cleanup_initialized(sys.DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD) THEN
DBMS_OUTPUT.put_line('YES');
ELSE
DBMS_OUTPUT.put_line('NO');
END IF;
END;
/

YES


CREATE TABLESPACE TS_AUDIT DATAFILE '+DGDATA/tkrman/ts_audit_01.dbf' SIZE 128M
AUTOEXTEND ON NEXT 64M MAXSIZE 2G
NOLOGGING default NOCOMPRESS ONLINE PERMANENT BLOCKSIZE 8K
EXTENT MANAGEMENT LOCAL UNIFORM SIZE 16M SEGMENT SPACE MANAGEMENT AUTO;
  
  
BEGIN
SYS.DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
audit_trail_type => SYS.DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,
audit_trail_location_value => 'TS_AUDIT');
END;
/
 
 
BEGIN
SYS.DBMS_AUDIT_MGMT.set_audit_trail_location(
audit_trail_type           => SYS.DBMS_AUDIT_MGMT.AUDIT_TRAIL_FGA_STD,
audit_trail_location_value => 'TS_AUDIT');
END;
/
 
 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  