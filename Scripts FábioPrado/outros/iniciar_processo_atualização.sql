
-- limpar log ddl

! cp /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl/log.xml /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl/bkp_log.xml_pro_gmud20170511
! cp /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl_cdbprd1.log  /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/bkp_ddl_cdbprd1.log_pro_gmud20170511
! echo 1 > /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl/log.xml
! echo 1 > /orabin01/app/oracle/diag/rdbms/cdbprd1/cdbprd1/log/ddl_cdbprd1.log

-- enable user dbaass

ALTER USER DBAASS ACCOUNT UNLOCK;

-- disable jobs
alter system set job_queue_processes=0;

-- disable user
alter user OPENFIRE ACCOUNT LOCK;
alter user POS_EAD ACCOUNT LOCK;
alter user USER_S ACCOUNT LOCK;
alter user USER_SIUD ACCOUNT LOCK;



-- kill jobs em execução
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/kill_jobs.sql
SELECT 'exec DBMS_SCHEDULER.STOP_JOB (job_name => '||Chr(39)||owner||'.'||job_name||Chr(39)||');'
FROM dba_scheduler_running_jobs;
SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off

-- kill session
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/kill_session.sql

SELECT 'ALTER SYSTEM KILL SESSION '||Chr(39)||sid||','||serial#|| Chr(39)||' immediate;'
FROM gv$session where osuser != '26680503833';

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off


SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/disconnect_session.sql

select 'ALTER SYSTEM DISCONNECT SESSION '||Chr(39)||sid||','||serial#||Chr(39)||' IMMEDIATE;'
FROM gv$session where osuser != '26680503833';

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off


@/home/oracle/kill_session.sql

@/home/oracle/disconnect_session.sql

@/home/oracle/kill_jobs.sql

@/home/oracle/kill_session.sql

@/home/oracle/disconnect_session.sql

@/home/oracle/kill_jobs.sql

set lines 155
col username for a45
select username, account_status from dba_users where username in ('OPENFIRE','POS_EAD','USER_S','USER_SIUD');

SELECT 'exec DBMS_SCHEDULER.STOP_JOB (job_name => '||Chr(39)||owner||'.'||job_name||Chr(39)||');'
FROM dba_scheduler_running_jobs;

show parameter job;

-- execute atualização


