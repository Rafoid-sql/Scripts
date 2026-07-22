set lines 250 pages 999 verify off
ACCEPT sql_id CHAR PROMPT 'Enter sql_id > '

prompt Creating Tuning Task...

set serveroutput on
declare
 l_sql_tune_task_id  varchar2(100);
begin
 l_sql_tune_task_id := dbms_sqltune.create_tuning_task (
                          sql_id      => '&sql_id',
                          scope       => dbms_sqltune.scope_comprehensive,
                          time_limit  => 300,
                          task_name   => 'manual_&sql_id',
                          description => 'tuning task for statement &sql_id.');
dbms_output.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
end;
/

prompt Executing the tuning task...

exec dbms_sqltune.execute_tuning_task(task_name => 'manual_&sql_id');

prompt Displaying the recommendations...

set long 100000;
set longchunksize 1000
set pagesize 10000
set linesize 100
select dbms_sqltune.report_tuning_task('manual_&sql_id') as recommendations from dual;

undefine sql_id
