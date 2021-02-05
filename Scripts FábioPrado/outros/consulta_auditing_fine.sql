
-- As seguintes opções de auditoria se fazem valer através da política ORA_SECURECONFIG:

col POLICY_NAME format A20
col AUDIT_OPTION format A40
set PAGES 100
select POLICY_NAME, AUDIT_OPTION
	  from   AUDIT_UNIFIED_POLICIES
     where  policy_name =  'ORA_SECURECONFIG'  order by 2;
	 
	 
	 
	 
-- Para conferir as políticas já habilitadas vamos executar a seguinte query:

col user_name for a20
SELECT * FROM SYS.AUDIT_UNIFIED_ENABLED_POLICIES;


--Vamos consultar o que já temos de informações até o momento consultando somente as primeiras 5 linhas:

set pages 200 lin 200
col object_name for a30
sol username for a20
col dbusername for a20
col OS_USERNAME for a15
col AUDIT_OPTION for a15
COL TERMINAL FOR a15
col action_name for a20
col object_schema for a10
col sql_text for a70
col EVENT_TIMESTAMP for a30
select OS_USERNAME, TERMINAL, DBUSERNAME, ACTION_NAME, OBJECT_SCHEMA,
OBJECT_NAME, to_char(EVENT_TIMESTAMP,'dd/mm/yyyy hh24:mi:ss') EVENT_TIMESTAMP, AUDIT_OPTION 
from unified_audit_trail 
order by EVENT_TIMESTAMP 
fetch first 5 rows only;

-- consultar

SELECT dbusername, action_name, object_name,
2  system_privilege_used, unified_audit_policies
3  FROM  unified_audit_trail

-- CANCELAR AUDITORIA

noaudit policy ORA_SECURECONFIG by SYS;
