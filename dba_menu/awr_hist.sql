set lines 250 pages 999 verify off
col i for 9
col btime for a16
col module for a20 word_wrapped
col schema for a25 word_wrapped
select 
a.instance_number i,
to_char(a.begin_interval_time,'DD-MON-YY HH24:MI') btime,
b.plan_hash_value phv,
b.parsing_schema_name schema,
b.executions_delta "execs",
end_of_fetch_count_delta "eofd",
round(rows_processed_delta/decode(executions_delta,0,1,executions_delta)) "row/exec",
round(buffer_gets_delta/decode(executions_delta,0,1,executions_delta)) "gets/exec",
round(elapsed_time_delta/1000/decode(executions_delta,0,1,executions_delta)) "ela(ms)",
round(cpu_time_delta/1000/decode(executions_delta,0,1,executions_delta)) "cpu(ms)",
round(clwait_delta/1000/decode(executions_delta,0,1,executions_delta)) "cl(ms)",
round(ccwait_delta/1000/decode(executions_delta,0,1,executions_delta)) "cc(ms)",
round(apwait_delta/1000/decode(executions_delta,0,1,executions_delta)) "ap(ms)"
  from sys.wrh$_sqlstat b, sys.wrm$_snapshot a
 where
   executions_delta > 0 and
   a.snap_id = b.snap_id
   and a.dbid = b.dbid
   and b.instance_number=a.instance_number
   and sql_id ='&1'
   and a.begin_interval_time > sysdate - &2/24
--    and a.begin_interval_time between to_timestamp('23-JUL-14 08.30.00.606 AM') and to_timestamp('23-JUL-14 09.30.36.606 AM')
order by a.snap_id,a.begin_interval_time;
