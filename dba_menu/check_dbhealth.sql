REM Purpose: This script will gather data from db for hungdb check
REM Author:  Chandan Acharya
REM Version: 1.0 10/23/2020 CAchary - Initial Version

set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
set lines 250 pages 999
col event for a40
col machine for a30
col module for a20
col username for a15
col client_pid for a10
col server_pid for a10
col host_name for a20

prompt DB Instance Information... 
select name,instance_name,status,open_mode,startup_time,host_name,database_role,blocked
from gv$instance,v$database;

prompt Gather ASH information for last 15 mins...
col event for a50
select * from (
select inst_id,decode(session_state,'WAITING',event,'ON CPU') event,
count(*) total_wait_time,
round(count(*) / (sum(count(*)) over ()) * 100,1) pct
from gv$active_session_history
where
sample_time between (sysdate-15/1440) and sysdate
group by inst_id,
decode(session_state,'WAITING',event,'ON CPU')
order by pct desc
) where rownum <= 10
/

prompt Active Sessions with seconds_in_wait > 0...
SELECT
  s.inst_id ,
  s.sid,
  s.serial#,
  s.status,
  s.username,
  s.sql_id,
  substr(s.event,1,40) event,
  s.seconds_in_wait,
  count(*) session_cnt
FROM
  gv$session s, gv$process p
WHERE
 s.inst_id=p.inst_id and
 s.paddr = p.addr  and
s.type = 'USER'
and s.status='ACTIVE'
and seconds_in_wait > 0
group by
  s.inst_id ,
  s.sid,
  s.serial#,
  s.status  ,
  s.username,
  s.sql_id,
  substr(s.event,1,40),
  s.seconds_in_wait
order by seconds_in_wait
/
