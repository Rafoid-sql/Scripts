alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set lines 250 pages 999
col options for a10
col object_owner for a20
col object_name for a30
col execs for 9999999999
col avgrows for 9999999999
col ela/exec for 99999999999
col gets/exec for 99999999999
col cpu/exec for 99999999999
col last_active_time for a25
select distinct a.inst_id,a.sql_id,b.options,b.object_owner,b.object_name,a.executions execs,
       round(rows_processed/decode(executions,0,1,executions)) avgrows,
       round(elapsed_time/decode(executions,0,1,executions)/1000) "ela/exec",
       round(buffer_gets/decode(executions,0,1,executions)) "gets/exec",
       a.last_active_time
  from gv$sql_plan b, gv$sqlstats a
 where b.options like '%FULL%'
   and b.object_owner not in ('SYS', 'SYSTEM', 'DBSNMP', 'SYSMAN')
   and b.sql_id=a.sql_id
   and a.inst_id = b.inst_id
   and b.filter_predicates is not null
   and a.executions > 9
   and a.sql_text not like '%SQL Analyze%'
   and round(buffer_gets/decode(executions,0,1,executions),1) > 1000
--  and a.executions > 500
order by "gets/exec"
;
