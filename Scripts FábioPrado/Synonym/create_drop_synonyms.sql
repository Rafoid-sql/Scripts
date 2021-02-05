spool create_synonym.sql

SELECT 	'CREATE OR REPLACE PUBLIC SYNONYM ' || ob1.object_name, ' FOR DBAASS'||'.'|| ob1.object_name||';'
      FROM all_objects ob1
     WHERE ob1.owner = 'DBAASS'
       AND ob1.object_name not like 'BIN$%'
       AND ob1.object_type in ( 'FUNCTION','MATERIALIZED VIEW','PROCEDURE'
                          ,'SEQUENCE','TABLE','VIEW','PACKAGE','PACKAGE BODY');
spool off;



spool drop_synonym.sql

SELECT 	'DROP PUBLIC SYNONYM ' || ob1.object_name||';'
      FROM all_objects ob1
     WHERE ob1.owner = 'DBAASS'
       AND ob1.object_name not like 'BIN$%'
       AND ob1.object_type in ( 'FUNCTION','MATERIALIZED VIEW','PROCEDURE'
                          ,'SEQUENCE','TABLE','VIEW','PACKAGE','PACKAGE BODY');
spool off;



spool /home/oracle/drop_synonym.sql

SELECT 	'DROP SYNONYM ' || ob1.object_name||';'
      FROM all_objects ob1
	    WHERE  ob1.object_type = 'SYNONYM' 
		AND ob1.owner = 'DBAASS' 
		and ob1.object_name like 'U_%'
		--AND ob1.owner NOT IN ('USER_S','USER_SIUD','USER_BI') 
		--AND ob1.owner LIKE 'U_%';
         spool off