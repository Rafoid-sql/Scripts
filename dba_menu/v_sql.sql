set lines 250 pages 999 verify off
col inst for 99
col module for a20
col schema for a25
col last_active_time for a20
col execs for 99999999
col avgrows for 999999999
col ela(ms) for 999999999.999
col gets/exe for 9999999999.999
col sql_plan_baseline for a25
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
SELECT inst_id inst,sql_id,plan_hash_value phv, executions execs,end_of_fetch_count eofc,
parsing_schema_name schema,
ROUND (rows_processed / DECODE (executions, 0, 1, executions),3) "avgrows",
ROUND (elapsed_time / DECODE (executions, 0, 1, executions) / 1000,3) "ela(ms)",
--ROUND (cpu_time / DECODE (executions, 0, 1, executions) / 1000,3) "cpu(ms)",
ROUND (buffer_gets / DECODE (executions, 0, 1, executions),3) "gets/exe", module, last_active_time
FROM gv$sql
WHERE sql_id = '&1'
order by last_active_time;
