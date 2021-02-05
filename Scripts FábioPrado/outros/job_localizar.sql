-- Localizar Job execução
select
   rj.job_name,
   s.username,
   s.sid,
   s.serial#,
   p.spid,
   s.lockwait,
   s.logon_time
from 
   dba_scheduler_running_jobs rj,
   v$session s,
   v$process p
where
   rj.session_id = s.sid
and
   s.paddr = p.addr
order by
   rj.job_name
;

-- Matar Job

BEGIN SYS.DBMS_IJOB.BROKEN(729,TRUE); END;
/