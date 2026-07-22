set lines 250 pages 999 verify off
col object_name for a30
col table_name for a30
col index_name for a30
col column_name for a30
col event for a50
col machine for a50
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
alter session set current_schema=&SCHEMA_NAME;
