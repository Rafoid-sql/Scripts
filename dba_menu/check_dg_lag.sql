set line 200
col value for a20
prompt dataguard stats...
select name,value,unit,time_computed from v$dataguard_stats;

prompt checking mrp status...
select inst_id,process, status,thread#, sequence#,blocks from gv$managed_standby;

prompt last applied sequence# on standby...
set feed off 
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
set line 1000
select thread#,sequence#,applied,completion_time, first_time, next_time,fal
FROM v$archived_log
WHERE (thread#, completion_time) IN (SELECT thread#, MAX (completion_time)
                         FROM v$archived_log
                        WHERE applied = 'YES' group by thread#);

SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied",
(ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference"
  FROM (SELECT THREAD# ,SEQUENCE#
  FROM V$ARCHIVED_LOG
  WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME)
  FROM V$ARCHIVED_LOG
  GROUP BY THREAD#)) ARCH,
  (SELECT THREAD# ,SEQUENCE#
  FROM V$LOG_HISTORY
  WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME)
  FROM V$LOG_HISTORY
  GROUP BY THREAD#)) APPL
  WHERE ARCH.THREAD# = APPL.THREAD#
  ORDER BY 1;

