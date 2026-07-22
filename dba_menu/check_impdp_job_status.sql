-- sql_text
set lines 250 pages 999
col job_name for a30
col owner_name for a30
col sql_text for a70 word_wrapped
col message for a60 word_wrapped
select x.job_name,b.state,b.job_mode,b.degree
, x.owner_name
, p.totalwork, p.sofar
, round((p.sofar/p.totalwork)*100,2) pct_done
, p.time_remaining
, z.sql_text
, p.message
from dba_datapump_jobs b
left join dba_datapump_sessions x on (x.job_name = b.job_name)
left join v$session y on (y.saddr = x.saddr)
left join v$sql z on (y.sql_id = z.sql_id)
left join v$session_longops p ON (p.sql_id = y.sql_id)
WHERE y.module='Data Pump Worker'
AND p.time_remaining > 0;

--resumable , status
col error_msg for a50 word_wrapped
select name, sql_text, error_msg from dba_resumable;
