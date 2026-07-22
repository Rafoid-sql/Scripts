col sql_id for a15
col max_sample_time for a25
col sid for 99999
col serial# for 999999
col program for a30
col temp_space_gb for 9999
set lines 250 pages 999
prompt
prompt Listing max_sample_time,sql_id,session,program,temp_space_used causing ORA-1652 error
prompt
select max(sample_time) max_sample_time,sql_id,sid,serial#,program,max(temp_space_gb) temp_space_gb
from
(
select
max(sample_time) sample_time,sql_id,session_id sid,session_serial# serial#,program,round(max(temp_space_allocated/1024/1024/1024)) temp_space_gb
from dba_hist_active_sess_history h, dba_hist_snapshot s
where h.dbid=s.dbid
and h.instance_number=s.instance_number
and h.snap_id=s.snap_id
and s.begin_interval_time > 
(select to_date(to_char(max(originating_timestamp),'MM/DD/YYYY HH24:MI:SS'),'MM/DD/YYYY HH24:MI:SS')-30/1440 from 
v$diag_alert_ext  where message_text like '%ORA-01652%extend%temp%')
and s.begin_interval_time <= 
(select to_date(to_char(max(originating_timestamp),'MM/DD/YYYY HH24:MI:SS'),'MM/DD/YYYY HH24:MI:SS')+5/1440 from  
v$diag_alert_ext  where message_text like '%ORA-01652%extend%temp%')
group by sql_id,session_id,session_serial#,program
having round(max(temp_space_allocated/1024/1024/1024)) >= 8
)
group by sql_id,sid,serial#,program
order by temp_space_gb
/
