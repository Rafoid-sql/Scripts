set lines 250 pages 999
col i for 9
col username for a30
col machine for a50
col program for a50
prompt
prompt Session count by username,machine...
select inst_id i,username,machine,count(*)
from gv$session
where
type='USER'
and username is not null
group by inst_id,username,machine
order by 1,2,3
/

clear columns;

