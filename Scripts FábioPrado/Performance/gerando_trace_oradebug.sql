# capturando sessão para geração de trace

## consultando o consumidor de cpu.

		set lines 165
		set pagesize 150
		col module for a40
		col username for a20
		col terminal for a20
		col sql_id for a20
		col spid for a15
		SELECT distinct(s.sid), s.SQL_ID, p.spid as "OS PID",s.username,  s.module,
		st.value/100 as "CPU sec", sq.elapsed_time
		FROM v$sesstat st, v$statname sn, v$session s, v$process p, v$sql sq WHERE sn.name = 'CPU used by this session' 
		AND st.statistic# = sn.statistic# 
		AND s.sql_id = sq.sql_id 
		AND st.sid = s.sid AND s.paddr = p.addr AND s.last_call_et < 1800
		AND s.sql_id = '79q5jzrx7ucm3'
		AND s.logon_time > (SYSDATE-(240/1440)) ORDER BY 6 desc;
		
	

## pegando o spid 

select s.username, p.spid os_process_id, p.pid oracle_process_id
from v$session s, 	v$process p where s.paddr=p.addr and
s.sid=&sid; 

15367

## capturando a sessão pelo oradebug
oradebug setospid 151203

## descobrindo o nome do arquivo trace_file e colocando ilimitado
oradebug tracefile_name
oradebug unlimit

## Colocando em trace
ORADEBUG EVENT 10046 TRACE NAME CONTEXT FOREVER, LEVEL 12;

## parando o trace
ORADEBUG EVENT 10046 TRACE NAME CONTEXT OFF;

#####

	set lines 165
	set pagesize 150
	col module for a35
	col osuser for a20
	SELECT s.sid, s.serial#, p.spid as "OS PID",s.username,s.osuser, s.module,
	st.value/100 as "CPU sec"
	FROM v$sesstat st, v$statname sn, v$session s, v$process p WHERE sn.name = 'CPU used by this session' 
	AND st.statistic# = sn.statistic# 
	AND st.sid = s.sid AND s.paddr = p.addr AND s.last_call_et < 1800
	AND s.logon_time > (SYSDATE-(240/1440)) ORDER BY s.username desc;

	
********************************************************************************
count    =  Número de vezes que executou a query
cpu      =  tempo de CPU na execução
elapsed  =  tempo total gasto para executar
disk     =  número de leituras físicas de buffer(memória)
query    =  memória consistente lida
current  =  number of buffers gotten in current mode (usually for update)
rows     =  Número de linhas processadas pelo comando.
********************************************************************************
