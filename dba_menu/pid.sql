set lines 250 pages 999 verify off
col username for a20
col event for a25
col machine for a20
col spid for a10
col process for a10
col osuser for a10
col siw for 999999
col lcet for 999999
col id for 9
col sid for 99999
SELECT
  s.inst_id id,
  s.status    ,
  s.username ,
  s.sid       ,
  s.serial#   ,
  s.sql_id,
  s.event,
  s.last_call_et lcet,
  s.seconds_in_wait siw,
  s.process,
  p.spid,
  s.machine
FROM
  gv$session s, gv$process p
WHERE
 s.inst_id=p.inst_id and
 s.paddr = p.addr  and
s.type = 'USER'
and p.spid=&1
order by last_call_et desc;
