

-- habilitar trace

select s.username, p.spid os_pro_id, p.pid oracle_pro_id 
from v$session s, v$process p 
where s.paddr = p.addr and s.sid = '&user';

oradebug setospid 11926;
oradebug tracefile_name;
oradebug unlimit;
oradebug event 10046 trace name context forever, level 12;
