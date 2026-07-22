set lines 250 pages 999 verify off
col plan_hash_value for  99999999999999999
col min_bit for a30
col max_bit for a30
select min(a.begin_interval_time) min_bit ,max(a.begin_interval_time) max_bit,b.plan_hash_value,
max(round(buffer_gets_delta/decode(executions_delta,0,1,executions_delta))) max_bgets,
max(round(rows_processed_delta/decode(executions_delta,0,1,executions_delta))) max_rows_per_exec
  from sys.wrh$_sqlstat b, sys.wrm$_snapshot a
 where
   a.snap_id = b.snap_id
   and a.dbid = b.dbid
   and b.instance_number=a.instance_number
   and sql_id ='&1'
   and a.begin_interval_time > sysdate - &2
group by b.plan_hash_value
/
