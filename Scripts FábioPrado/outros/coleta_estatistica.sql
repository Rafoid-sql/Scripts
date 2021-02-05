SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 500
spool /home/oracle/estatistica_TABLE.sql

SELECT --NUM_ROWS,LAST_ANALYZED, 
'EXEC sys.dbms_stats.gather_table_stats(ownname => '''||OWNER||''', tabname => '''||TABLE_NAME||''', estimate_percent => 100, method_opt => ''FOR ALL COLUMNS SIZE AUTO'', granularity => ''ALL'', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);'
FROM dba_tab_statistics
where owner IN ('DBAASS')
AND TABLE_NAME LIKE 'OLI%'
TABLE_NAME LIKE 'MGR%'
--and NUM_ROWS < 100
and LAST_ANALYZED < SYSDATE - 3;

SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off
==========================================================


declare

cursor c01 is
  SELECT object_name
    FROM user_objects
   WHERE object_type = 'TABLE'
     AND object_name LIKE 'PROVA_ALUNO%';
begin

for r_c01 in c01 loop

   DBMS_STATS.GATHER_TABLE_STATS('DBAASS', r_c01.object_name, estimate_percent => 100, method_opt => 'FOR ALL COLUMNS SIZE AUTO', granularity => 'ALL', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);
end loop;

end;
/


=======================================================

declare

cursor c01 is
  
SELECT table_name
FROM dba_tab_statistics
where owner IN ('DBAASS')
and LAST_ANALYZED < SYSDATE - 3
and NUM_ROWS > 100;

begin

for r_c01 in c01 loop

   DBMS_STATS.GATHER_TABLE_STATS('DBAASS', r_c01.table_name, estimate_percent => 100, method_opt => 'FOR ALL COLUMNS SIZE AUTO', granularity => 'ALL', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);
end loop;

end;
/



===================================================

SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 1000
spool /home/oracle/coleta_dba.sql
SELECT --NUM_ROWS,LAST_ANALYZED, owner,table_name,
'EXEC sys.dbms_stats.gather_table_stats(ownname => '''||OWNER||''', tabname => '''||TABLE_NAME||''', estimate_percent => 50, method_opt => ''FOR ALL COLUMNS SIZE AUTO'', granularity => ''ALL'', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);'
FROM dba_tab_statistics
where LAST_ANALYZED < SYSDATE - 4
and owner IN ('DBAASS')
and table_name not like 'X$%'
and NUM_ROWS < 2000000
order by 1 desc;
SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off


CENSO_ALUNO_HISTORICO
==================================

declare
begin
DBMS_STATS.GATHER_DATABASE_STATS(estimate_percent => 70
,block_sample => FALSE
,method_opt => 'for all columns size 1'
,degree => null
,granularity => 'ALL'
,cascade => TRUE
,stattab => null
,statid => null
,options => 'GATHER STALE'
,statown => null
,gather_sys => FALSE
,no_invalidate => FALSE
,gather_temp => TRUE
,gather_fixed => FALSE
,stattype => 'ALL');
end;



+++++++++++++++++++++++++++

declare
begin
DBMS_STATS.GATHER_DATABASE_STATS(estimate_percent => 33
,block_sample => FALSE
,method_opt => 'for all columns size 1'
,degree => null
,granularity => 'ALL'
,cascade => TRUE
,stattab => null
,statid => null
,options => 'GATHER'
,statown => null
,gather_sys => FALSE
,no_invalidate => FALSE
,gather_temp => TRUE
,gather_fixed => FALSE
,stattype => 'ALL');
end;



