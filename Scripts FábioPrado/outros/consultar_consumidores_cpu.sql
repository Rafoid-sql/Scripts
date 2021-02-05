
-- SQLS de sessões ativas no momento
SELECT s.sid
     , x.sql_id
     , ((x.elapsed_time / 1000000) / x.executions) "Média tempo p/ exec. (s)"
     , ((x.cpu_time / 1000000) / x.executions) "Média cpu_time (s)"
     , (((x.elapsed_time / 1000000) / x.executions) + ((x.cpu_time / 1000000) / x.executions)) ordenacao
     , x.sql_text
     , s.machine || ', ' || s.TERMINAL || ', ' || s.PROGRAM local_exec
     , x.executions
     , x.first_load_time
     , x.last_load_time "Carregado no cache"
  FROM gv$session s
     , v$sql x
 WHERE s.status = 'ACTIVE'
   AND x.sql_id = s.sql_id
   --and x.sql_id = 'dg6phxcgpzpgz'
   AND x.executions > 0
   AND ROWNUM < 21
 ORDER BY ordenacao DESC
  
 
-- SQLs que mais consumiram recursos nos últimos 5 minutos
-- retorna os top SQL por elapsed_time dos últimos 5 minutos
SELECT u.username
    , a.sql_id
    , dbms_lob.substr(a.sql_fulltext, 4000, 1) sql_text
    , a.executions
    , ((a.elapsed_time / (1000000)) / a.executions) "Média tempo p/ exec. (s)"
    , ((a.cpu_time / 1000000) / a.executions) "Média cpu_time (s)"
    , a.disk_reads       
    , a.last_active_time
    , a.rows_processed
    , a.application_wait_time / (1000000) "application_wait_time (s)"
    , a.concurrency_wait_time / (1000000) "concurrency_wait_time (s)"
    , a.user_io_wait_time / (1000000) "user_io_wait_time (s)"
    , a.plsql_exec_time / (1000000) "plsql_exec_time (s)"
    , a.optimizer_mode
    , a.optimizer_cost
    , (a.sharable_mem + a.persistent_mem + a.runtime_mem) / 1024 / 1024 "Memória utilizada (MB)"
    , (((a.elapsed_time / (1000000)) / a.executions) + ((a.cpu_time / 1000000) / a.executions)) ordenacao
 FROM v$sqlarea a,
      dba_users u
WHERE a.last_active_time BETWEEN SYSDATE - 0.00695 AND SYSDATE
  AND a.executions > 0
  AND u.user_id = a.parsing_user_id
  AND u.username NOT IN ('SYS', 'SYSTEM', 'ZABBIX', 'PERFSTAT')
  --AND ROWNUM < 21
--ORDER BY executions DESC; -- numero de execuções
   ORDER BY 5 desc; -- Média tempo p/ exec. (s)
-- ORDER BY 6 DESC; --Média Cpu time (s)
 

-- consulta cpu / client_info

SELECT 
     distinct s.sid
    --, s.serial#
    --, s.status
    --, client_info
    , st.value/100 as "CPU sec"
    , espe_tipo
    , espe_nome
    , s.username
   -- , sql_exec_start
   , s.program
 --  , s.action
   , a.sql_text
   -- , s.machine
 FROM v$session s
    , vm_especializacao
    , v$sesstat st
    , v$statname sn
    , v$process p
    , v$sqlarea a
WHERE to_char(espe_codi(+)) = client_info
      AND sn.name = 'CPU used by this session' 
      AND st.statistic# = sn.statistic# 
      AND st.sid = s.sid
      and s.sql_id = a.sql_id
      and s.status = 'ACTIVE'
     -- AND s.paddr = p.addr 
     -- AND s.last_call_et < 1800
      AND s.logon_time > (SYSDATE-(240/1440)) ORDER BY 2 DESC;
	  
	  
	  
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

-- ver estatisticas relacionadas a servicos
select  service_name,
        stat_name,
       trunc((value / 1000000),2)
from    v$service_stats
order by 3 desc, 1, 2


-- consultar objeto mais executados

select      OWNER, 
            NAMESPACE, 
            TYPE,             
            ROUND(SHARABLE_MEM /1024/1024,5) as "SHARABLE_MEM (MB)", 
            LOADS, 
            EXECUTIONS, 
            LOCKS,
            --pins,
            KEPT,
            invalidations,
            CHILD_LATCH,
            NAME
from        v$db_object_cache
where       type not in ( 'NOT LOADED','NON-EXISTENT','VIEW','TABLE','SEQUENCE') 
and         executions>0 and loads>1 and kept='NO'
order by    executions desc, owner, namespace, type;

