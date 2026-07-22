set lines 300 pages 999 verify off
col sid for 999999
col serial# for 999999
col username for a20
COL "MACHINE" FORMAT A20 HEAD 'MACHINE' WORD_WRAPPED
COL "EVENT" FORMAT A25 HEAD 'EVENT' WORD_WRAPPED
col program for a30
col status for a15
col wait_class for a15
col process for a10
col spid for a10
col bls for 999999
col lcet for 99999
col siw for 99999
SELECT
  S.INST_ID ,
  S.STATUS    ,
  S.USERNAME ,
  S.SID ,
  S.SERIAL#   ,
  S.SQL_ID,
  S.EVENT,
  S.LAST_CALL_ET lcet,
  S.SECONDS_IN_WAIT siw,
  s.blocking_session bls,
  P.SPID ,
  S.MACHINE
FROM
  GV$SESSION S, GV$PROCESS P
WHERE
 S.INST_ID=P.INST_ID AND
 S.PADDR = P.ADDR  AND
S.TYPE = 'USER'
AND S.SID=&1
order by last_call_et
/
