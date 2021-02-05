select      a.event,
            a.total_waits,
            a.time_waited,
            round(a.time_waited/a.total_waits,5) average_wait,
            round(sysdate - b.startup_time,2) days_old
from        v$system_event a,
            v$instance b
order by    4 desc


==========================


-- Verificar lentidao no banco

select w.sid, w.event, w.seconds_in_wait, dbms_lob.substr(sqa.sql_fulltext, 4000, 1) sql_text 
from v$session_wait w, v$session s, v$process p, v$sqltext sq, v$sqlarea sqa
where w.sid = s.sid
and s.paddr = p.addr
and sq.address = s.sql_address
and sq.hash_value = sqa.hash_value
and sq.hash_value = s.PREV_HASH_VALUE
and w.wait_class != 'Idle' 
and w.con_id = s.con_id
and w.con_id = p.con_id
and w.con_id = sq.con_id
order by w.seconds_in_wait desc;