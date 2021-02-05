select      * 
from        dba_role_privs 
where       granted_role = 'DBA'
order by    grantee


	select * from (
	select 'revoke '||privilege||' from '||grantee||';' from dba_sys_privs
	where grantee in ('&USUARIO')
	union all
	select 'revoke '||privilege||' on '||grantor||'.'||table_name||' from '||grantee||';' from dba_tab_privs
	where grantee in ('&USUARIO')
	union all
	select 'revoke '||GRANTED_ROLE||' from '||grantee||';' from dba_role_privs
	where grantee in ('&USUARIO'));
	
	
