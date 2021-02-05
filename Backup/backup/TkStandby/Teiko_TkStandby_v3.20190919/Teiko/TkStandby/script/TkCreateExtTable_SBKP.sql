
whenever sqlerror exit;

accept DirArchiveDest  char prompt "Informe o caminho dos Archives (Log_Archive_Dest):"
accept ExternalFileNameRPO char prompt "Informe o Nome do Archivo Source da External Table Default (RPO_<ORACLE_SID>.txt):"
accept ExternalFileNameRTO char prompt "Informe o Nome do Archivo Source da External Table Default (RTO_<ORACLE_SID>.txt):"
accept ExternalFileNameTWU char prompt "Informe o Nome do Archivo Source da External Table Default (TWU_<ORACLE_SID>.txt):"

Prompt
Prompt Create Directory : StdbyDirExtTable_SBKP
Prompt ===================================
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from sys.dba_directories where directory_name = 'STDBYDIREXTTABLE_SBKP'; 
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop directory STDBYDIREXTTABLE_SBKP';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   


create directory StdbyDirExtTable_SBKP as '&DirArchiveDest';


Prompt
Prompt Creating Standby Teiko User
Prompt =========================== 
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from sys.dba_users where username = 'TEIKOSTDBY_SBKP'; 
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop user TEIKOSTDBY_SBKP cascade';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   

create user Teikostdby_SBKP identified by teikostdby_SBKP;


Prompt
Prompt Grants to TeikoStdby_SBKP user
Prompt ============================================
Prompt 
grant create session to TeikoStdby_SBKP;
GRANT READ ON DIRECTORY StdbyDirExtTable_SBKP TO Teikostdby_SBKP; 
GRANT write ON DIRECTORY StdbyDirExtTable_SBKP TO Teikostdby_SBKP; 
grant select any dictionary to TeikoStdby_SBKP;
grant select on v_$loghist to TeikoStdby_SBKP;
grant resource to TeikoStdby_SBKP;
grant sysdba to TeikoStdby_SBKP;

Prompt
Prompt Creating Table TK_SLA_CONTROL
Prompt ============================================
Prompt

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_SLA_CONTROL' and OWNER = 'TEIKOSTDBY_SBKP';
    IF P_EXISTS = 1 THEN
        P_COMMAND := 'drop table TEIKOSTDBY_SBKP.TK_SLA_CONTROL';
        EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/

CREATE TABLE TEIKOSTDBY_SBKP.TK_SLA_CONTROL
( TIME_CONFERENCE     DATE)
/
  

Prompt
Prompt Atualizando Table TK_SLA_CONTROL
Prompt ============================================
Prompt 
INSERT INTO TEIKOSTDBY_SBKP.TK_SLA_CONTROL VALUES (SYSDATE)
/

Prompt
Prompt Creating External Table TK_RPO_TABLE_CONTROL
Prompt ============================================
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_RPO_TABLE_CONTROL' and OWNER = 'TEIKOSTDBY_SBKP';
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop table TEIKOSTDBY_SBKP.TK_RPO_TABLE_CONTROL';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   


CREATE TABLE TEIKOSTDBY_SBKP.TK_RPO_TABLE_CONTROL
( THREAD#          NUMBER,
  SEQUENCE#        NUMBER,
  TIME_REPLICATION DATE
)
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY stdbyDirexttable_sbkp
  ACCESS PARAMETERS
(
  records delimited by newline
  nologfile
  nobadfile
  nodiscardfile
  fields terminated by ':'
  ("THREAD#", "SEQUENCE#", TIME_REPLICATION DATE 'YYYYMMDDHH24MISS')
)
LOCATION ('&ExternalFileNameRPO')
)
/


Prompt
Prompt Creating External Table TK_RTO_TABLE_CONTROL
Prompt ============================================
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_RTO_TABLE_CONTROL' and OWNER = 'TEIKOSTDBY_SBKP';
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop table TEIKOSTDBY_SBKP.TK_RTO_TABLE_CONTROL';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   


CREATE TABLE TEIKOSTDBY_SBKP.TK_RTO_TABLE_CONTROL
( ID_ACTION    NUMBER,
  TIME_UPDATE  DATE
)
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY stdbyDirexttable_sbkp
  ACCESS PARAMETERS
(
  records delimited by newline
  nologfile
  nobadfile
  nodiscardfile
  fields terminated by ':'
  (ID_ACTION, TIME_UPDATE DATE 'YYYYMMDDHH24MISS')
)
LOCATION ('&ExternalFileNameRTO')
)
/

Prompt
Prompt Creating External Table TK_TWU_TABLE_CONTROL
Prompt ============================================
Prompt

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_TWU_TABLE_CONTROL' and OWNER = 'TEIKOSTDBY_SBKP';
    IF P_EXISTS = 1 THEN
        P_COMMAND := 'drop table TEIKOSTDBY_SBKP.TK_TWU_TABLE_CONTROL';
        EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/


CREATE TABLE TEIKOSTDBY_SBKP.TK_TWU_TABLE_CONTROL
( THREAD#          NUMBER,
  SEQUENCE#        NUMBER,
  TIME_CURRENT     DATE
)
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY stdbyDirexttable_SBKP
  ACCESS PARAMETERS
(
  records delimited by newline
  nologfile
  nobadfile
  nodiscardfile
  fields terminated by ':'
  ("THREAD#", "SEQUENCE#", TIME_CURRENT DATE 'YYYYMMDDHH24MISS')
)
LOCATION ('&ExternalFileNameTWU')
)
/

