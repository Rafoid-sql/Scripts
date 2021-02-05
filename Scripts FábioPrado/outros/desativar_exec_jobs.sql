SELECT 'EXEC dbms_scheduler.disable (''' || owner || '.' || job_name || ''');' 
    FROM dba_scheduler_jobs 
    WHERE enabled = 'TRUE'
	and owner='DBAASS'
    ORDER BY owner, job_name;