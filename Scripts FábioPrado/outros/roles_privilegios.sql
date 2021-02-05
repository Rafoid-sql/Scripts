select      * 
from        dba_role_privs 
where       granted_role = 'DBA'
order by    grantee

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
set pagesize 3000
spool /home/oracle/R_NUTEC_DEV.sql
	select * from (
	select 'revoke '||privilege||' from '||grantee||';' from dba_sys_privs
	where grantee in ('R_NUTEC_DEV') --and privilege in ('SELECT','INSERT','UPDATE', 'DELETE')
	union all
	select 'revoke '||privilege||' on '||grantor||'.'||table_name||' from '||grantee||';' from dba_tab_privs
	where grantee in ('R_NUTEC_DEV') --AND privilege in ('SELECT','INSERT','UPDATE', 'DELETE')
	union all
	select 'revoke '||GRANTED_ROLE||' from '||grantee||';' from dba_role_privs
	where grantee in ('R_NUTEC_DEV')); --AND GRANTED_ROLE in ('SELECT','INSERT','UPDATE', 'DELETE'));
	spool off
	SET HEADING ON 
	set FEEDBACK ON
	SET VERIFY ON
	
	
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/usersiud.sql

select * from (
	select 'revoke '||privilege||' from '||grantee||';' from dba_sys_privs
	where grantee in ('USER_SIUD')
	union all
	select 'revoke '||privilege||' on '||grantor||'.'||table_name||' from '||grantee||';' from dba_tab_privs
	where grantee in ('USER_SIUD'));

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
spool /home/oracle/usersiud.sql
	
set lines 155
set pagesize 3000
	select * from (
	select 'revoke '||privilege||' from '||grantee||';' from dba_sys_privs
	where grantee in ('&user')
	union all
	select 'revoke '||privilege||' on '||grantor||'.'||table_name||' from '||grantee||';' from dba_tab_privs
	where grantee in ('&user')
	union all
	select 'revoke '||GRANTED_ROLE||' from '||grantee||';' from dba_role_privs
	where grantee in ('&user'));

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/


================================================

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/GRANT_pos_ead.sql
	
set lines 155
set pagesize 3000
	select * from (
	select 'GRANT '||privilege||' TO '||grantee||';' from dba_sys_privs
	where grantee in ('U_DECIO_LEHMKUHL')
	union all
	select 'GRANT '||privilege||' on '||grantor||'.'||table_name||' TO '||grantee||';' from dba_tab_privs
	where grantee in ('U_DECIO_LEHMKUHL')
	union all
	select 'GRANT '||GRANTED_ROLE||' TO '||grantee||';' from dba_role_privs
	where grantee in ('U_DECIO_LEHMKUHL'));

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/

================================================


	
	select role from dba_roles order by 1;
	
	
	
	
	select * from (
	select 'revoke '||privilege||' from '||grantee||';' from dba_sys_privs
	where privilege in ('&priv') and grantee='R_NUTEC_DEV'
	union all
	select 'revoke '||privilege||' on '||grantor||'.'||table_name||' from '||grantee||';' from dba_tab_privs
	where privilege in ('&priv') and grantee='R_NUTEC_DEV'
	union all
	select 'revoke '||GRANTED_ROLE||' from '||grantee||';' from dba_role_privs
	where GRANTED_ROLE in ('&priv') and grantee='R_NUTEC_DEV');
 
 
 ================== clonar permissoes ==========
 
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/user_mobile.sql
set lines 155
set pagesize 3000
	select * from (
	select 'grant '||privilege||' to '||'USER_MOBILE'||';' from dba_sys_privs
	where grantee in ('USER_SIUD')
	union all
	select 'grant '||privilege||' on '||grantor||'.'||table_name||' to '||'USER_MOBILE'||';' from dba_tab_privs
	where grantee in ('USER_SIUD')
	union all
	select 'grant '||GRANTED_ROLE||' to '||'USER_MOBILE'||';' from dba_role_privs
	where grantee in ('USER_SIUD'));
SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
/


=============== Quem esta recebendo a role =========================

set lines 155
set pagesize 3000
	select 'revoke '||GRANTED_ROLE||' from '||grantee||';' from dba_role_privs
	where granted_role in ('&role');