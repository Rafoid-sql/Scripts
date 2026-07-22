set lines 250 pages 999
col event for a40 word_wrapped
col job_name for a40 word_wrapped
col owner_name for a40 word_wrapped
col lcet for 999999
select
   sid,
   serial# ,
   event,
   s.sql_id,
   s.seconds_in_wait,
   s.last_call_et lcet,
   d.job_name,
   d.owner_name,
   s.program,
   s.module
from
   gv$session s,
   dba_datapump_sessions d
where
   s.saddr = d.saddr
and s.inst_id=d.inst_id   
and wait_class <> 'Idle'
and s.status='ACTIVE'
/
