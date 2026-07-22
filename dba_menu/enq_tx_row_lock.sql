col i for 9
col sid for 999999
col bls for 999999
col bli for 9
col sql_id for a13
col row_id for a13
col event for a40 WORD_WRAPPED
col lcet for 99999999
col obj for a25
col row_id for a20
set lines 250 pages 999
prompt Checking enq: TX - row lock contention details...
select inst_id i,sid,blocking_session bls,blocking_instance bli,sql_id,event,last_call_et lcet,wait_time_micro,
(select object_name from dba_objects where object_id = row_wait_obj#) obj,
decode(event,'enq: TX - row lock contention',dbms_rowid.ROWID_CREATE(1,ROW_WAIT_OBJ#,ROW_WAIT_FILE#,ROW_WAIT_BLOCK#,ROW_WAIT_ROW#),null) row_id
from gv$session 
where status = 'ACTIVE' 
and type = 'USER'
and event='enq: TX - row lock contention' 
order by last_Call_et
/
