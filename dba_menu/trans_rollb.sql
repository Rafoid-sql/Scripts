/* active */
set lines 250 pages 999 verify off
col username for a25
col sid for 99999
col ublks for 999999
col urecs for 999999
col cgets for 999999
col "SQL" for a60 HEAD 'SQL' WORD_WRAPPED
select u.inst_id,
       u.username,
       u.sid,
       u.sql_id,
       t.used_ublk ublks,
       t.used_urec urecs,
       t.cr_get cgets,
       t.start_time "Trans Start Time",
       s.sql_text "SQL"
from gv$session u
   , gv$transaction t
   , gv$sql s
where u.taddr(+)=t.addr
  and u.prev_sql_id = s.sql_id(+)
  and u.username is not null
  and u.inst_id=t.inst_id
  and u.sid=&1
order by t.start_time;
