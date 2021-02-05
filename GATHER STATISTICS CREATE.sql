SET SERVEROUTPUT ON
DECLARE
l_job NUMBER;
BEGIN
SELECT MAX (job) + 1 INTO l_job FROM dba_jobs;
DBMS_JOB.submit(l_job,
'BEGIN DBMS_STATS.gather_dictionary_stats; END;',
trunc(next_day(SYSDATE,'SUNDAY'))+1/24,
'TRUNC (SYSDATE+7)+2/24');
COMMIT;
DBMS_OUTPUT.put_line('Job: ' || l_job);
END;
/

--=============================================================================================================================

SET SERVEROUTPUT ON
DECLARE
l_job NUMBER;
BEGIN
SELECT MAX (job) + 1 INTO l_job FROM dba_jobs;
DBMS_JOB.submit(l_job,
'BEGIN DBMS_STATS.gather_schema_stats(''TOTVS'',estimate_percent => dbms_stats.auto_sample_size, degree=>16 ); END;',
trunc(next_day(SYSDATE,'SUNDAY'))+3/24,
'TRUNC (SYSDATE+7)+3/24');
COMMIT;
DBMS_OUTPUT.put_line('Job: ' || l_job);
END;
/

--=============================================================================================================================

SET SERVEROUTPUT ON
DECLARE
l_job NUMBER;
BEGIN
SELECT MAX (job) + 1 INTO l_job FROM dba_jobs;
DBMS_JOB.submit(l_job,
'BEGIN DBMS_STATS.gather_database_stats(estimate_percent => dbms_stats.auto_sample_size, degree=>16 ); END;',
trunc(next_day(SYSDATE,'SUNDAY'))+2/24,
'TRUNC (SYSDATE+7)+4/24');
COMMIT;
DBMS_OUTPUT.put_line('Job: ' || l_job);
END;
/

--=============================================================================================================================

EXEC DBMS_STATS.gather_dictionary_stats;

EXEC DBMS_STATS.gather_schema_stats(''TOTVS'',estimate_percent => dbms_stats.auto_sample_size, degree=>16);

EXEC DBMS_STATS.gather_database_stats(estimate_percent => dbms_stats.auto_sample_size, degree=>16);