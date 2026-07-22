set lines 250 pages 999 verify off feed off
col table_name for a30
col owner for a30
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
prompt dba_tables info...
select t.owner,t.table_name,last_analyzed,num_rows,partitioned part,round(sum(s.bytes)/1024/1024,1) size_mb
from dba_tables t, dba_segments s
where t.owner=s.owner
and t.table_name=s.segment_name
and t.owner=upper('&&1')
and t.table_name=upper('&&2')
group by t.owner,t.table_name,last_analyzed,num_rows,partitioned;

prompt dba_tab_col_statistics info...
col owner for a20
col column_name for a30
select owner,table_name,column_name,num_distinct,num_nulls,last_analyzed,histogram from dba_tab_col_statistics where owner=upper('&&1') and table_name=upper('&&2');

undefine 1
undefine 2
