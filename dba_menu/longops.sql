alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set lines 250 pages 999
col username for a20
col opname for a15
col estd_end_time for a20
col message for a45 word_wrapped
col pct_done for 999
select 
s.inst_id,s.sid,s.username,s.opname,s.sql_id,
sysdate + time_remaining/3600/24 estd_end_time,round((sofar/totalwork)*100) pct_done, s.message
from gv$session_longops s
where sofar <> totalwork
/
