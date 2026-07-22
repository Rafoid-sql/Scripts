prompt
prompt Listing targets which not in "Target Up" or "Blackout" status in asmdba_group group
prompt

set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on

set lines 250 pages 999
col target_name for a50
col target_type for a30
col availability_status for a30
col start_timestamp for a30
select mc.target_name,mc.target_type,start_timestamp,availability_status 
from sysman.mgmt$availability_current mc, sysman.mgmt$group_members mg, sysman.mgmt_targets t
where mc.target_guid=mg.target_guid
and   mc.target_guid=t.target_guid
and mc.target_type <> 'oracle_dbsys'
and mc.availability_status not in ('Target Up','Blackout')
and t.host_name not like 'admtrac%'
and t.host_name not like 'devspz%'
and mg.group_name='asmdba_group'
order by start_timestamp
/
