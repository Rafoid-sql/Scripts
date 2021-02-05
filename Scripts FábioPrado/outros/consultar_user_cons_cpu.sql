set lines 200
col CLIENT_INFO for a10
col ESPE_NOME for a35
col MACHINE for a35
SELECT 
     distinct s.sid
    --, s.serial#
    --, s.status
    , client_info
    , st.value/100 as "CPU sec"
    , espe_nome
    , espe_tipo
   -- , sql_exec_start
    , s.program
    --, s.machine
    , s.username
 FROM v$session s
    , vm_especializacao
    , v$sesstat st
    , v$statname sn
    , v$process p
WHERE to_char(espe_codi(+)) = client_info
      AND sn.name = 'CPU used by this session' 
      AND st.statistic# = sn.statistic# 
      AND st.sid = s.sid
      and s.status = 'ACTIVE'
     -- AND s.paddr = p.addr 
     -- AND s.last_call_et < 1800
      AND s.logon_time > (SYSDATE-(240/1440)) ORDER BY 3 DESC;