
--bkp log ddl gmud

! cp /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl/log.xml /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl/log.xml_gmud_20170412
! cp /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl_cdbprd1.log  /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl_cdbprd1.log_gmud_20170412
! echo 1 > /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl/log.xml
! echo 1 > /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl_cdbprd1.log

alter system set enable_ddl_logging=FALSE scope=BOTH;

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/create_synonym_i.sql

SELECT 	'CREATE OR REPLACE PUBLIC SYNONYM ' || ob1.object_name, ' FOR DBAASS'||'.'|| ob1.object_name||';'
      FROM all_objects ob1
     WHERE ob1.owner = 'DBAASS'
	 and object_name = 'INTEGRACAO_DIGITALPAGES'
       --AND ob1.object_name in ('f_retorna_log_registro')
       AND ob1.object_type in ( 'FUNCTION','MATERIALIZED VIEW','PROCEDURE'
                          ,'SEQUENCE','TABLE','VIEW','PACKAGE','PACKAGE BODY');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off

-- condeder permissão a novos objetos
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/grant_execute_i.sql

select  'GRANT EXECUTE ON ' || OWNER || '.' || object_name || ' TO R_EXECUTE_DEV;'
from    dba_objects
where   owner = UPPER('DBAASS')
and object_name = 'INTEGRACAO_DIGITALPAGES'
and     object_type in ('PROCEDURE','PACKAGE','FUNCTION');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/


SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/grant_select_i.sql

select  'GRANT SELECT ON ' || OWNER || '.' || object_name || ' TO R_CONSULTA_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and object_name = 'INTEGRACAO_DIGITALPAGES'
and     object_type IN ('TABLE','VIEW','MATERIALIZED VIEW');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/grant_delete_i.sql

select  'GRANT DELETE ON ' || OWNER || '.' || object_name || ' TO R_DELETE_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and object_name = 'INTEGRACAO_DIGITALPAGES'
and     object_type IN ('TABLE');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/grant_insert_i.sql

select  'GRANT INSERT ON ' || OWNER || '.' || object_name || ' TO R_INSERT_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and object_name = 'INTEGRACAO_DIGITALPAGES'
and     object_type IN ('TABLE');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set pagesize 3000
set lines 155
spool /home/oracle/grant_update.sql

select  'GRANT UPDATE ON ' || OWNER || '.' || object_name || ' TO R_UPDATE_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and object_name = 'INTEGRACAO_DIGITALPAGES'
and     object_type IN ('TABLE');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/

@/home/oracle/create_synonym_i.sql

@/home/oracle/grant_select_i.sql

@/home/oracle/grant_insert_i.sql

@/home/oracle/grant_execute_i.sql

@/home/oracle/grant_update_i.sql

@/home/oracle/grant_delete_i.sql

alter system set enable_ddl_logging=TRUE scope=BOTH;