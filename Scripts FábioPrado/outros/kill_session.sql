SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/kill_session.sql

SELECT 'ALTER SYSTEM KILL SESSION '||Chr(39)||sid||','||serial#|| Chr(39)||' immediate;'
FROM gv$session where  sid in ('38');

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off


SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/disconnect_session.sql

select 'ALTER SYSTEM kill SESSION '||Chr(39)||sid||','||serial#||Chr(39)||' IMMEDIATE;'
FROM gv$session where OSUSER = 'nginx' or sql_id = '379xfb0kjmkvc' ;

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off

@/home/oracle/kill_session.sql

@/home/oracle/disconnect_session.sql



-- Matar sessão pelo SID

SELECT 'ALTER SYSTEM KILL SESSION '||Chr(39)||s.sid||','||s.serial#|| Chr(39)||' immediate;'
   FROM v$session s
    WHERE s.sid = &sid
      and s.status = 'ACTIVE'
      ORDER BY 1 DESC;
	  
	  
-- Matar sessão pelo NOME

	SELECT 'ALTER SYSTEM KILL SESSION '||Chr(39)||s.sid||','||s.serial#|| Chr(39)||' immediate;'
	   FROM 
	   vm_especializacao
	   , v$session s
		WHERE  to_char(espe_codi(+)) = client_info
		  --s.sid = &sid
		  and espe_nome = '&nome'
		  and s.status = 'ACTIVE'
		  ORDER BY 1 DESC;
	  
	  

