-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 300 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
SELECT INSTANCE_NUMBER,SNAP_ID,BEGIN_INTERVAL_TIME,END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT WHERE BEGIN_INTERVAL_TIME > SYSTIMESTAMP -2 ORDER BY BEGIN_INTERVAL_TIME ASC;

EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;


@$ORACLE_HOME/rdbms/admin/awrrpt.sql
@$ORACLE_HOME/rdbms/admin/awrrpti.sql
@$ORACLE_HOME/rdbms/admin/awrgdrpt.sql


SET TERMOUT OFF
COLUMN today_col NEW_VALUE today
SELECT TO_CHAR (SYSDATE, 'YYYYMMDD') AS today_col FROM dual; 
SET TERMOUT ON
SPOOL '/home/oracle/advisor_&sqlid._&today..log'


spool /home/oracle/advisor_3tzpp57r4349s_20240205.log

--CREATING THE TASK:
set lines 300
set linesize 10000
set long 65536
set longchunksize 65536
DECLARE
  l_sql_tune_task_id  VARCHAR2(100);
BEGIN
	l_sql_tune_task_id := DBMS_SQLTUNE.create_Tuning_task (
						begin_snap	=> &&begin_snap,
						end_snap	=> &&end_snap,
						sql_id      => '&&sql_id',
						scope       => DBMS_SQLTUNE.scope_comprehensive,
						time_limit  => 60000,
						task_name   => 'Tuning_3_&&sql_id',
						description => 'Tuning task for statement &&sql_id .');
	DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/

--CREATING THE REPORT:
set lines 280
set linesize 10000
set long 65536
set longchunksize 65536
EXEC DBMS_SQLTUNE.execute_Tuning_task(task_name => 'Tuning_3_&&sql_id');
/

--FOLLOW THE REPORT CREATION:
SELECT TASK_NAME,STATUS,PCT_COMPLETION_TIME,EXECUTION_START FROM DBA_ADVISOR_LOG WHERE TASK_NAME='Tuning_3_6cu1a684fuwuy';

COL TASK_NAME FOR A30
COL "COMP_%" FOR A6
SELECT TASK_NAME, STATUS, TO_CHAR(PCT_COMPLETION_TIME) AS "COMP_%", EXECUTION_START AS "START" FROM DBA_ADVISOR_LOG WHERE EXECUTION_START >= TO_DATE('2025-09-30 07:17:00','YYYY-MM-DD HH24:MI:SS') ORDER BY EXECUTION_START;

--GENERATING THE REPORT:
set lines 300
set linesize 10000
set long 65536
set longchunksize 65536
SELECT DBMS_SQLTUNE.REPORT_Tuning_TASK('Tuning_3_&&sql_id') FROM DUAL;
/

SET LONG 2000000 PAGESIZE 0 FEEDBACK OFF
SELECT DBMS_SQLTUNE.report_tuning_task(task_name => 'Tuning_3_6cu1a684fuwuy') FROM dual;

--DROPPING THE REPORT:
set lines 300
set linesize 10000
set long 65536
set longchunksize 65536
EXEC DBMS_SQLTUNE.DROP_Tuning_TASK('Tuning_3_&&sql_id');

spool off;

6cu1a684fuwuy



COL NODE FOR 99
COL FROM_WHEN FOR A15
COL FROM_WHERE FOR A20
COL START_TIME FOR A15
COL SID FOR 99999
COL SERIAL# FOR 99999
COL PROGRAM FOR A25
COL OSUSER FOR A10
COL BLOCK_SESS FOR A10
COL "%_COMP" FOR A6
COL "T/S/R(min)" FOR A14
SELECT * FROM (
SELECT  SE.INST_ID NODE, SL.SID, SL.SERIAL#, SL.SQL_ID, STATUS, SCHEMANAME || '@' || REGEXP_SUBSTR(SERVICE_NAME, '[^.]+') AS FROM_WHERE, OSUSER, SUBSTR(PROGRAM, 1, INSTR(PROGRAM, ' ') - 1) AS PROGRAM, BLOCKING_SESSION BLOCK_SESS, TO_CHAR(LOGON_TIME,'MON-DD HH24:MI:SS') FROM_WHEN, TO_CHAR(START_TIME,'MON-DD HH24:MI:SS') START_TIME, CEIL((ELAPSED_SECONDS + TIME_REMAINING) / 60) || '/' || FLOOR(ELAPSED_SECONDS / NULLIF(60,0)) || '/' || CEIL(TIME_REMAINING / NULLIF(60,0)) "T/S/R(min)", TO_CHAR(ROUND(SOFAR / NULLIF(TOTALWORK, 0), 4) * 100) "%_COMP"
FROM GV$SESSION SE
JOIN GV$SESSION_LONGOPS SL ON SE.SID = SL.SID AND SE.SERIAL# = SL.SERIAL#
JOIN GV$SQLAREA SA ON SL.SQL_ID = SA.SQL_ID
WHERE TYPE = 'USER'
)
WHERE "%_COMP" <> 100
--WHERE L.SQL_ID = A.SQL_ID AND L.SQL_ID = S.SQL_ID AND L.SID = S.SID AND TYPE = 'USER' AND TOTALWORK > 0 AND SOFAR != TOTALWORK
--AND SQL_ID = '6q352kuy53kcd'
AND SID IN (830)
ORDER BY STATUS, OSUSER, PROGRAM;