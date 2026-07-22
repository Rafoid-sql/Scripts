prompt Checking invalid objects...
set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
set head on pages 1000 lines 600
col owner for a30
col object_name for a30
select owner, object_name,object_type,created,last_ddl_time from dba_objects where status='INVALID' order by last_ddl_time;
