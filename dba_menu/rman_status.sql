set lines 250 pages 999
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
col opname for a50
SELECT
  inst_id,
  sid,
  start_time,
  totalwork,
  sofar,
  opname,
  round(((sofar/totalwork) * 100),2) pct_done,
  sysdate + time_remaining/3600/24 estimated_end_time
FROM
   gv$session_longops
WHERE
   totalwork > sofar
AND
   opname NOT LIKE '%aggregate%'
AND
   opname like 'RMAN%';

