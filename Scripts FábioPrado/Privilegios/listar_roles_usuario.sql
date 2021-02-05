-- o script retorna as roles que um usuario possui
SELECT
nvl(b.grantee,'No_Roles_Granted'),nvl(b.granted_role,'null')
from
dba_users a,dba_role_privs b
where a.username =b.grantee(+) and grantee=('&NOME_USUARIO');

"U_herminio.kloch"

eeDo4viwduch5aiP