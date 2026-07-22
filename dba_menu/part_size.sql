set lines 250 pages 999 feed on verify off
col partition_name for a30
prompt size by partition...
select sp.partition_name,sum(s.bytes)/1024/1024 "SIZE_MB"
from dba_tab_partitions sp, dba_segments s
where s.segment_name=sp.table_name
and s.owner=sp.table_owner
and sp.partition_name=s.partition_name
and s.owner=upper('&&1')
and sp.table_name=upper('&&2')
group by sp.partition_name
order by 1;

prompt size by subpartition...
select s.owner,sp.partition_name,sum(s.bytes)/1024/1024 "SIZE_MB"
from dba_tab_subpartitions sp, dba_segments s
where s.segment_name=sp.table_name
and s.owner=sp.table_owner
and sp.subpartition_name=s.partition_name
and s.owner=upper('&1')
and sp.table_name=upper('&2')
group by s.owner,sp.partition_name
order by 2;

undefine 1
undefine 2

