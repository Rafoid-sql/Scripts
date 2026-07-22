set lines 250 pages 999
col sid for a20
col wait_event for a60
col chain_id for a20
SELECT decode( a.blocker_sid , NULL , '<chain id#' ||a.chain_id||'>' ) chain_id,
       RPAD( '+' , LEVEL , '-' ) ||a.sid sid,
       RPAD( ' ' , LEVEL , ' ' ) ||a.wait_event_text wait_event
FROM   V$WAIT_CHAINS  a
CONNECT BY PRIOR a.sid=a.blocker_sid
AND    PRIOR a.sess_serial#=a.blocker_sess_serial#
AND    PRIOR a.instance = a.blocker_instance START WITH a.blocker_is_valid='FALSE'
ORDER  BY a.chain_id ,LEVEL;
