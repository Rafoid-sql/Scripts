col owner for a30
col object_name for a30
col object_type for a20
set lines 250 pages 999 verify off
set echo off feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set echo on feed on
select owner,object_name,object_type,created,last_ddl_time
from
dba_objects
where object_name = upper('&1')
order by last_ddl_time
/
