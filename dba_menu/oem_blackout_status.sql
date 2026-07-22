prompt
prompt Listing targets which are in blackout status in asmdba_group group
prompt

set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on

set lines 250 pages 999
col blackout_name for a50
col blackout_start_time for a19
col target_name for a45
col target_type for a15
col reason for a24
col status for a20
select b.blackout_name,blackout_start_time,t.target_name,t.target_type,substr(reason,1,25) reason
from sysman.gc$blackout_targets b,sysman.mgmt_targets t,sysman.mgmt$group_members mg
where
b.target_name=t.target_name
and mg.target_guid=t.target_guid
and b.status not in('Stopped','Ended')
and mg.group_name='asmdba_group'
and t.target_type <> 'oracle_home'
and t.host_name not like 'admtrac%'
and b.blackout_name <> 'Temp_blackout_2019'
and b.reason not like '%Decommissioning%'
and t.target_type in ('oracle_emd','host','oracle_database','rac_database','osm_cluster','oracle_listener')
order by blackout_start_time,blackout_name
/
