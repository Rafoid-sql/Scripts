
whenever sqlerror exit;

accept DirArchiveDest  char prompt "Informe o caminho dos Archives (Log_Archive_Dest):"
accept ExternalFileNameRPO char prompt "Informe o Nome do Archivo Source da External Table Default (RPO_<ORACLE_SID>.txt):"
accept ExternalFileNameRTO char prompt "Informe o Nome do Archivo Source da External Table Default (RTO_<ORACLE_SID>.txt):"
accept ExternalFileNameTWU char prompt "Informe o Nome do Archivo Source da External Table Default (TWU_<ORACLE_SID>.txt):"

Prompt
Prompt Create Directory : StdbyDirExtTable
Prompt ===================================
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from sys.dba_directories where directory_name = 'STDBYDIREXTTABLE'; 
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop directory STDBYDIREXTTABLE';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   


create directory StdbyDirExtTable as '&DirArchiveDest';


Prompt
Prompt Creating Standby Teiko User
Prompt =========================== 
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from sys.dba_users where username = 'TEIKOSTDBY'; 
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop user TEIKOSTDBY cascade';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   

create user Teikostdby identified by teikostdby;


Prompt
Prompt Grants to TeikoStdby user
Prompt ============================================
Prompt 
grant create session to TeikoStdby;
GRANT READ ON DIRECTORY StdbyDirExtTable TO Teikostdby; 
GRANT write ON DIRECTORY StdbyDirExtTable TO Teikostdby; 
grant select any dictionary to TeikoStdby;
grant select on v_$loghist to TeikoStdby;
grant resource to TeikoStdby;
grant sysdba to TeikoStdby;

Prompt
Prompt Creating Table TK_SLA_CONTROL
Prompt ============================================
Prompt

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_SLA_CONTROL' and OWNER = 'TEIKOSTDBY';
    IF P_EXISTS = 1 THEN
        P_COMMAND := 'drop table TEIKOSTDBY.TK_SLA_CONTROL';
        EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/

CREATE TABLE TEIKOSTDBY.TK_SLA_CONTROL
( TIME_CONFERENCE     DATE)
/
  

Prompt
Prompt Atualizando Table TK_SLA_CONTROL
Prompt ============================================
Prompt 
INSERT INTO TEIKOSTDBY.TK_SLA_CONTROL VALUES (SYSDATE)
/

Prompt
Prompt Creating External Table TK_RPO_TABLE_CONTROL
Prompt ============================================
Prompt 

DECLARE
P_EXISTS NUMBER;
P_COMMAND VARCHAR2(255);
BEGIN
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_RPO_TABLE_CONTROL' and OWNER = 'TEIKOSTDBY';
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop table TEIKOSTDBY.TK_RPO_TABLE_CONTROL';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   


CREATE TABLE TEIKOSTDBY.TK_RPO_TABLE_CONTROL
( THREAD#          NUMBER,
  SEQUENCE#        NUMBER,
  TIME_REPLICATION DATE
)
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY stdbyDirexttable
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
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_RTO_TABLE_CONTROL' and OWNER = 'TEIKOSTDBY';
    IF P_EXISTS = 1 THEN
    	P_COMMAND := 'drop table TEIKOSTDBY.TK_RTO_TABLE_CONTROL';
    	EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/   


CREATE TABLE TEIKOSTDBY.TK_RTO_TABLE_CONTROL
( ID_ACTION    NUMBER,
  TIME_UPDATE  DATE
)
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY stdbyDirexttable
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
    select count(*) into P_EXISTS from DBA_OBJECTS where OBJECT_NAME = 'TK_TWU_TABLE_CONTROL' and OWNER = 'TEIKOSTDBY';
    IF P_EXISTS = 1 THEN
        P_COMMAND := 'drop table TEIKOSTDBY.TK_TWU_TABLE_CONTROL';
        EXECUTE IMMEDIATE P_COMMAND;
    END IF;
END;
/


CREATE TABLE TEIKOSTDBY.TK_TWU_TABLE_CONTROL
( THREAD#          NUMBER,
  SEQUENCE#        NUMBER,
  TIME_CURRENT     DATE
)
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY stdbyDirexttable
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

