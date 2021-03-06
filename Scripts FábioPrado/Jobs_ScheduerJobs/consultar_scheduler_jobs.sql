-- consultando jobs criados com o SCHEDULER
SELECT      j.OWNER, 
            j.JOB_NAME,
            j.JOB_TYPE,
            j.JOB_ACTION,
            TO_CHAR(j.START_DATE, 'dd/mm/yyyy hh24:mi:ss TZR') START_DATE,
            to_char(j.last_start_date, 'dd/mm/yyyy hh24:mi:ss TZR') last_start_date,
            j.LAST_RUN_DURATION, 
            to_char(j.next_run_date, 'dd/mm/yyyy hh24:mi:ss TZR') next_run_date,
            j.STATE,
            j.ENABLED,
            j.run_count,
            j.failure_count,
            j.repeat_interval,
            r.session_id,
            r.ELAPSED_TIME,
            j.EVENT_QUEUE_OWNER,
            j.EVENT_QUEUE_AGENT,
            j.EVENT_CONDITION
FROM        dba_scheduler_jobs j
LEFT JOIN   DBA_SCHEDULER_RUNNING_JOBS r
    ON      r.owner = j.owner
    and     r.job_name = j.job_name
where       j.owner = 'DBAASS'
    and     j.STATE = 'RUNNING'



-- query e tempo de execução passando sid

SELECT OSUSER, SERIAL#, SID, executions, sql.SQL_ID ,sql.child_number, SQL_TEXT, sql.ELAPSED_TIME/1000000/60 MINUTOS, sql.ELAPSED_TIME/1000000/60/60 HORAS
FROM V$SESSION sess JOIN V$SQL sql 
on  (sess.SQL_ADDRESS = sql.ADDRESS) 
where sess.STATUS = 'ACTIVE' and
sess.sid = 1438;

desc dba_scheduler_jobs
    
-- consultando informacoes de log dos jobs
SELECT      *
FROM        DBA_SCHEDULER_JOB_LOG
where       owner = 'HR';

-- consultando informacoes detalhadas sobre jobs executados
SELECT      *
FROM        DBA_SCHEDULER_JOB_RUN_DETAILS
where       owner = 'HR';
  
-- consultando notificacoes de jobs
SELECT      *
FROM        DBA_SCHEDULER_NOTIFICATIONS;
  
  
-- consultando PROGRAMS
SELECT      *
FROM        DBA_SCHEDULER_PROGRAMS
WHERE       OWNER = 'HR';

-- consultando SCHEDULES
SELECT      *
FROM        DBA_SCHEDULER_SCHEDULES
WHERE       OWNER = 'HR';

-- consultando CHAINS
SELECT      *
FROM        DBA_SCHEDULER_CHAINS
WHERE       OWNER = 'HR';

-- consultando CHAINS em execucao
SELECT      *
FROM        DBA_SCHEDULER_RUNNING_CHAINS;

-- consultando passos de CHAINS
SELECT      *
FROM        DBA_SCHEDULER_CHAIN_STEPS;

-- consultando regras dos passos de CHAINS
SELECT      *
FROM        DBA_SCHEDULER_CHAIN_RULES;

--
set lines 190
col username for a15
col schemaname for a15
col module for a20
select username,schemaname,status,program,type,module,action from v$session where module='DBMS_SCHEDULER';