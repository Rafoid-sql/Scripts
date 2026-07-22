set lines 250 pages 999 verify off
col sql_id for a15
col max_bit for a25
col module for a40
col parsing_schema_name for a30
col max_px_per_exec for 9999
select * from
(
select
sql_id,
max(a.begin_interval_time) max_bit,
b.module,
b.parsing_schema_name,
max(round(px_servers_execs_delta/decode(executions_delta,0,1,executions_delta))) max_px_per_exec
  from sys.wrh$_sqlstat b, sys.wrm$_snapshot a
where
parsing_schema_name <> 'DBSNMP'
 and executions_delta > 0
 and a.snap_id = b.snap_id
 and a.dbid = b.dbid
 and b.instance_number=a.instance_number
 and a.begin_interval_time > sysdate-&1
group by sql_id,module,parsing_schema_name
)
where max_px_per_exec > 16
order by max_px_per_exec
/
