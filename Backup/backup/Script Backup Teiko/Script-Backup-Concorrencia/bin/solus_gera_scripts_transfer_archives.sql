set term off feedback off verify off pages 0 lines 2000 trimspool on head off
SPOOL '/home/oracle/scripts/bin/SOLUS_TRANSFERE_ARCHIVE_TO_STANDBY.sh';
select distinct  'asmcmd cp ' ||name || ' /u02/solus/archives'||substr(name,23,50)
from gv$archived_log
where
DELETED = 'NO' and resetlogs_change# = '20534769413' and
not exists (select sequence from transfer_arc.transfered_files
           where sequence# = sequence and thread# = thread)
order by 1;

SPOOL off;
SPOOL '/home/oracle/scripts/bin/SOLUS_GRAVA_LOG_ARCHIVE_TRANSFERIDO.sql';
SELECT * FROM (
SELECT DISTINCT 'INSERT INTO TRANSFERED_FILES VALUES ('''||name||''','||SEQUENCE#||','''
||TO_CHAR(completion_time,'DD-MON-YYYY HH24:MI:SS')||''','''||TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||''','||THREAD#||');'
from gv$archived_log
where
DELETED = 'NO' and resetlogs_change# = '20534769413' and
not exists (select sequence from transfer_arc.transfered_files
           where sequence# = sequence and thread# = thread)
order by 1
)
DUAL
union all
SELECT 'COMMIT;' FROM DUAL
union all
SELECT 'exit;' FROM DUAL;
SPOOL off;
exit

