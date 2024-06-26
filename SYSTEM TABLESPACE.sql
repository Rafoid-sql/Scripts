set lines 300 pagesize 3000
col SEGMENT_NAME for a60
SELECT OWNER,SEGMENT_NAME,SEGMENT_TYPE,EXTENTS,BLOCKS,BYTES/1024/1024 as MB
FROM DBA_SEGMENTS
WHERE TABLESPACE_NAME='SYSTEM'
ORDER BY BYTES DESC;

--Check out MOS note 1328239.1 which will walk you through the process, but paraphrasing
--1) create a new tablespace
CREATE TABLESPACE AUDIT_TBS DATAFILE '/u01/app/oracle/oradata/d1v11202/audit_tbs1.dbf' SIZE 100M AUTOEXTEND ON; 

--2) move the tables there
SQL> BEGIN
DBMS_AUDIT_MGMT.SET_AUDIT_TRAIL_LOCATION(
AUDIT_TRAIL_TYPE => DBMS_AUDIT_MGMT.AUDIT_TRAIL_AUD_STD,--THIS MOVES TABLE AUD$
AUDIT_TRAIL_LOCATION_VALUE => 'AUDIT_TBS');
END;
/