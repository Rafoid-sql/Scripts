set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
set lines 250 pages 999
select 
input_type,
status,
round(max(output_bytes)/1024/1024/1024) size_gb,
round(max(elapsed_seconds)/60) ela_mins,
max(start_time) start_time,
max(end_time) end_time
from v$rman_backup_job_details
group by input_type,status
/
