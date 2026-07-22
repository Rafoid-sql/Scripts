set lines 250 pages 999
col i for 9
col username for a30
col machine for a50
col program for a50
prompt
prompt Session count by username...
select inst_id i,username,count(*)
from gv$session
where
type='USER'
and username is not null
group by inst_id,username
order by 3,1
/

clear columns;

