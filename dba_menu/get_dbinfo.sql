set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set lines 250 pages 999
col name for a8
col db_unique_name for a15
col log_mode for a15
col open_mode for a15
col flg for a5
col flashback_on for a10
col current_scn for 9999999999999999999999999
col supp_log_min for a15
select name,db_unique_name,log_mode,open_mode,database_role,switchover_status,force_logging flg,flashback_on,current_scn,supplemental_log_data_min supp_log_min
from v$database
/

col instance_name for a10
col host_name for a20
col version for a15
SELECT instance_name,host_name,version,startup_time,status,database_status,archiver,logins,blocked
from gv$instance
/
