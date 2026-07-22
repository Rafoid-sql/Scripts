set lines 250 pages 999 feed off verify off
col name for a30
col owner for a30
col object_type for a30
col column_name for a35
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
prompt dba_part_key_columns info...
select owner,name,object_type,column_name,column_position from dba_part_key_columns where owner=upper('&&1') and name=upper('&&2');

col column_name for a40
prompt dba_subpart_key_columns info...
select owner,name,object_type,column_name,column_position from dba_subpart_key_columns where owner=upper('&1') and name=upper('&2');

undefine 1
undefine 2

