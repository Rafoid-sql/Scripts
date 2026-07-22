set lines 300 pages 999
col i for 9
col sid for 999999
col serial# for 999999
col event for a35
col username for a20
col machine for a30
col program for a30
col status for a15
col wait_class for a15
col process for a10
col spid for a10
col bls for 9999999
col lcet for 99999999
col siw for 99999
prompt 
prompt Active sessions in database...
SELECT
  S.INST_ID I,
  S.USERNAME ,
  S.SID ,
  S.SERIAL#   ,
  S.SQL_ID,
  substr(S.EVENT,1,35) event,
  S.LAST_CALL_ET lcet,
  S.SECONDS_IN_WAIT siw,
  P.SPID ,
  substr(S.MACHINE,1,30) machine,
  s.blocking_session bls
FROM
  GV$SESSION S, GV$PROCESS P
WHERE
 S.INST_ID=P.INST_ID AND
 S.PADDR = P.ADDR  AND
S.TYPE = 'USER'
AND S.STATUS='ACTIVE'
order by last_call_et
/

clear columns;
