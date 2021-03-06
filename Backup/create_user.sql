CREATE TABLESPACE LB2BKP DATAFILE '/u01/app/oracle/oradata/viasoft/lb2bkp01.dbf' SIZE 2G AUTOEXTEND ON NEXT 256M MAXSIZE 16G;
CREATE DIRECTORY DATA_PUMP AS '/u01/app/oracle/backup/datapump/files';
CREATE USER LB2_BKP IDENTIFIED BY bkp#lb2 DEFAULT TABLESPACE LB2BKP;
GRANT RESOURCE TO LB2_BKP;
GRANT UNLIMITED TABLESPACE TO LB2_BKP;
GRANT CONNECT TO LB2_BKP;
GRANT CREATE SESSION TO LB2_BKP;
GRANT CREATE TABLE TO LB2_BKP;
GRANT DBA TO LB2_BKP;
GRANT EXP_FULL_DATABASE TO LB2_BKP;
GRANT IMP_FULL_DATABASE TO LB2_BKP; 
GRANT SELECT ON V_$INSTANCE TO LB2_BKP;
GRANT SELECT ON V_$DATABASE TO LB2_BKP;
GRANT SELECT ON V_$TEMP_SPACE_HEADER TO LB2_BKP;
GRANT SELECT ON GV_$INSTANCE TO LB2_BKP;
GRANT SELECT ON DBA_OBJECTS TO LB2_BKP;
GRANT SELECT ON DBA_DATA_FILES TO LB2_BKP;
GRANT SELECT ON DBA_FREE_SPACE TO LB2_BKP;
GRANT SELECT ON DBA_SEGMENTS TO LB2_BKP;
GRANT SELECT ON DBA_TABLESPACES TO LB2_BKP;
GRANT SELECT ON DBA_TEMP_FILES TO LB2_BKP;
GRANT SELECT ON DBA_USERS TO LB2_BKP;
GRANT SELECT ON SYSTEM.SCHEDULER_JOB_ARGS TO LB2_BKP;
GRANT SELECT ON SYSTEM.SCHEDULER_PROGRAM_ARGS TO LB2_BKP;
GRANT SELECT ON ORDDATA.ORDDCM_DOCS TO LB2_BKP;
GRANT SELECT ON WMSYS.WM$EXP_MAP TO LB2_BKP;
GRANT READ ON DIRECTORY DATA_PUMP TO LB2_BKP;
GRANT WRITE ON DIRECTORY DATA_PUMP TO LB2_BKP;
GRANT EXECUTE ON SYS.DBMS_DEFER_IMPORT_INTERNAL TO LB2_BKP;
GRANT EXECUTE ON SYS.DBMS_EXPORT_EXTENSION TO LB2_BKP;
GRANT FLASHBACK ON ORDDATA.ORDDCM_DOCS TO LB2_BKP;
GRANT FLASHBACK ON WMSYS.WM$EXP_MAP TO LB2_BKP;
GRANT FLASHBACK ON SYSTEM.SCHEDULER_JOB_ARGS TO LB2_BKP;
GRANT FLASHBACK ON SYSTEM.SCHEDULER_PROGRAM_ARGS TO LB2_BKP;
GRANT SELECT ON SYS.KU$_USER_MAPPING_VIEW TO LB2_BKP;
GRANT SELECT ON SYS.FGA_LOG$FOR_EXPORT TO LB2_BKP;
GRANT SELECT ON SYS.AUDTAB$TBS$FOR_EXPORT TO LB2_BKP;
GRANT SELECT ON SYS.DBA_SENSITIVE_DATA TO LB2_BKP;
GRANT SELECT ON SYS.DBA_TSDP_POLICY_PROTECTION TO LB2_BKP;
GRANT SELECT ON SYS.NACL$_ACE_EXP TO LB2_BKP;
GRANT SELECT ON SYS.NACL$_HOST_EXP TO LB2_BKP;
GRANT SELECT ON SYS.NACL$_WALLET_EXP TO LB2_BKP;
GRANT FLASHBACK ON SYS.KU$_USER_MAPPING_VIEW TO LB2_BKP;
GRANT FLASHBACK ON SYS.FGA_LOG$FOR_EXPORT TO LB2_BKP;
GRANT FLASHBACK ON SYS.AUDTAB$TBS$FOR_EXPORT TO LB2_BKP;
GRANT FLASHBACK ON SYS.DBA_SENSITIVE_DATA TO LB2_BKP;
GRANT FLASHBACK ON SYS.DBA_TSDP_POLICY_PROTECTION TO LB2_BKP;
GRANT FLASHBACK ON SYS.NACL$_ACE_EXP TO LB2_BKP;
GRANT FLASHBACK ON SYS.NACL$_HOST_EXP TO LB2_BKP;
GRANT FLASHBACK ON SYS.NACL$_WALLET_EXP TO LB2_BKP;