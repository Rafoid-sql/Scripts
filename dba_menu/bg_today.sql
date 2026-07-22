set lines 250 pages 999
select * from
(
select b.sql_id,sum(b.executions_Delta) exec,
       round(sum(b.rows_processed_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) ,2) AvgRowExe,
       round(sum(b.fetches_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) ,2) AvgFtchExe,
       round(sum(b.buffer_gets_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)),2) AvgBGetExe,
       round(sum(b.disk_reads_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)),2) AvgReadExe,
       round(sum(b.elapsed_time_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) AvgElaMs,
       round(sum(b.cpu_time_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) AvgCPUMs,
       round(sum(b.iowait_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) AvgIOExeMs,
       round(sum(b.ccwait_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) AvgCCExeMs,
       round(sum(b.clwait_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) AvgCLExeMs,
       round(sum(b.apwait_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) AvgAPExeMs
  from dba_users c, sys.wrh$_sqlstat b, sys.wrm$_snapshot a
 where a.begin_interval_time > trunc(sysdate)
   and a.snap_id = b.snap_id
   and a.dbid    = b.dbid
   and a.instance_number = b.instance_number
   and b.executions_delta > 0
   and b.parsing_schema_id = c.user_id
   and c.profile in ('APPLICATION_PROFILE','SCHEMA_PROFILE')
 group by sql_id
 having ((sum(b.executions_delta) > 10 AND sum(b.buffer_gets_delta)/sum(b.executions_delta) > 1000000) OR
        (sum(b.executions_delta) > 100 AND sum(b.buffer_gets_delta)/sum(b.executions_delta) > 100000) OR
        (sum(b.executions_delta) > 1000 AND sum(b.buffer_gets_delta)/sum(b.executions_delta) > 10000) OR
        (sum(b.executions_delta) > 10000 AND sum(b.buffer_gets_delta)/sum(b.executions_delta) > 1000) OR
        (sum(b.executions_delta) > 100000 AND sum(b.buffer_gets_delta)/sum(b.executions_delta) > 100) OR
        (sum(b.executions_delta) > 1000000 AND sum(b.buffer_gets_delta)/sum(b.executions_delta) > 50)) AND
        round(sum(b.elapsed_time_delta) / decode(sum(b.executions_delta),0,1,sum(b.executions_delta)) / 1000,2) > 10
 order by sum(buffer_gets_delta)  desc
)
where sql_id not in (select sql_id from system.sql_id_exceptions)
/
