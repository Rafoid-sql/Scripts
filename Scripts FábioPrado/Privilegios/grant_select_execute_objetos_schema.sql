
spool grant_execute.sql

select  'GRANT EXECUTE ON ' || OWNER || '.' || object_name || ' TO R_EXECUTE_DEV;'
from    dba_objects
where   owner = UPPER('DBAASS')
and     object_type in ('PROCEDURE','PACKAGE','FUNCTION');

spool off;
/
@/home/oracle/grant_execute.sql
/

spool grant_select.sql

select  'GRANT SELECT ON ' || OWNER || '.' || object_name || ' TO R_CONSULTA_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and     object_type IN ('TABLE','VIEW','MATERIALIZED VIEW');

spool off;
/
@/home/oracle/grant_select.sql
/

spool grant_delete.sql

select  'GRANT DELETE ON ' || OWNER || '.' || object_name || ' TO R_DELETE_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and     object_type IN ('TABLE');

spool off;
/
@/home/oracle/grant_delete.sql
/

spool grant_insert.sql

select  'GRANT INSERT ON ' || OWNER || '.' || object_name || ' TO R_INSERT_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and     object_type IN ('TABLE');

spool off;
/
@/home/oracle/grant_insert.sql
/

spool grant_update.sql

select  'GRANT UPDATE ON ' || OWNER || '.' || object_name || ' TO R_UPDATE_DBASS;'
from    dba_objects
where   owner = UPPER('DBAASS')
and     object_type IN ('TABLE');

spool off;
/
@/home/oracle/grant_update.sql
/


--R_EXECUTE_DEV

--  select * from (
--	select 'revoke '||privilege||' from '||grantee||';' from dba_sys_privs
--	where grantee in ('&USUARIO')
--	union all
--	select 'revoke '||privilege||' on '||grantor||'.'||table_name||' from '||grantee||';' from dba_tab_privs
--	where grantee in ('&USUARIO')
--	union all
--	select 'revoke '||GRANTED_ROLE||' from '||grantee||';' from dba_role_privs
--	where grantee in ('&USUARIO'));