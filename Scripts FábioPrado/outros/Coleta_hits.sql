spool coleta_hists_$ORACLE_SID.lst

PROMPT #######################################################
PROMPT ##													##
PROMPT ## Relatorio do Banco de Dados Produção - Uniasselvi ##
PROMPT ##													##
PROMPT #######################################################

PROMPT
set serveroutput on
alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss'; 

PROMPT
PROMPT >>>>>>>> INSTANCE NAME 
show parameter instance_name

PROMPT
PROMPT >>>>>>>> STARTUP TIME
select startup_time from v$instance;

PROMPT 
PROMPT >>>>>>>> PARAMETROS SPFILE
set lines 400
col NAME for a35
col VALUE for a60
select  NAME, VALUE from v$spparameter order by NAME;

PROMPT 
PROMPT >>>>>>>> PARAMETROS
show parameter

PROMPT 
PROMPT >>>>>>>> HITS MEMORIA ORACLE
set linesize 400

col "Buffer Hit Ratio" format a16;
col "Dictionary Hit Ratio" format a20;
col "Library Hit Ratio" format a17;
col "RedoLog Wait" format a12;
col "PGA Hit Ratio" format a13;
with
a as
(
  select to_char(round(((1-(sum(decode(name,'physical reads',value,0))/(sum(decode(name,'db block gets',value,0))+(sum(decode(name,'consistent gets',value,0))))))*100),4),'99.99') || '%' as "Buffer Hit Ratio"
  from v$sysstat
),
b as
(
  select to_char(round(((1-(sum(getmisses)/sum(gets)))*100),4),'999.99') || '%' as "Dictionary Hit Ratio"
  from v$rowcache
),
c as
(
  select to_char(round(100-((((sum(reloads)/sum(pins))))),4),'999.99') || '%' as "Library Hit Ratio"
  from v$librarycache
),
d as
(
  select to_char(round((100-(100*sum(decode(name,'redo log space requests',value,0))/sum(decode(name,'redo entries',value,0)))),4),'999.999') || '%' as "RedoLog Wait"
  from sys.v_$sysstat
),
e as
(
  select to_char(round(value,4),'999.99') ||'%' "PGA Hit Ratio"
  from sys.v_$pgastat
  where name = 'cache hit percentage'
)
select * from a,b,c,d,e;
PROMPT
PROMPT --Shared Pool Size (Execution Misses) - Deve estar a menos de 1%

set lines 155
set pagesize 400

column "Executions" format 999,999,999,990
column "Cache Misses Executing" format 999,999,990
column "Data Dictionary Gets" format 999,999,999,999,999
column "Get Misses" format 999,999,999,999
select sum(pins) "Executions",
sum(reloads) "Cache Misses Executing",
(sum(reloads)/sum(pins)*100) "%Ratio (STAY UNDER 1%)"--,
--(sum(pinhits)/sum(pins)*100) "%Ratio LC"
from v$librarycache;

PROMPT
PROMPT -- Estatística de Library Cache

select 	
	NAMESPACE,
	GETS,
	GETHITS,
	round(GETHITRATIO*100,2) gethit_ratio,
	PINS,
	PINHITS,
	round(PINHITRATIO*100,2) pinhit_ratio,
	RELOADS,
	INVALIDATIONS
from 	v$librarycache;
PROMPT
select * from v$library_cache_memory where lc_inuse_memory_size > 0;

PROMPT
PROMPT --Shared Pool Size (Dictionary Gets) - Deve estar abaixo de 12%

select sum(gets) "Data Dictionary Gets",
sum(getmisses) "Get Misses",
100*(sum(getmisses)/sum(gets)) "%Ratio (STAY UNDER 12%)"
from v$rowcache;

PROMPT
PROMPT -- Estatística do Dicionário

column parameter format a21
column pct_succ_gets format 999.9
column updates format 999,999,999
SELECT 
	parameter
	, sum(gets)
	, sum(getmisses)
	, 100*sum(gets - getmisses) / sum(gets) pct_succ_gets
	, sum(modifications) updates
FROM V$ROWCACHE
	WHERE gets > 0
GROUP BY rollup(parameter);

PROMPT
PROMPT -- Estatística do Dicionário "< 60%"

column parameter format a21
column pct_succ_gets format 999.9
column updates format 999,999,999
SELECT 
	parameter
	, sum(gets)
	, sum(getmisses)
	, to_char(100*sum(gets - getmisses) / sum(gets),'999D99') pct_succ_gets
	, sum(modifications) updates
FROM V$ROWCACHE
	WHERE gets > 0
GROUP BY rollup(parameter)
	HAVING 100*sum(gets - getmisses) / sum(gets) <= 60;

PROMPT
PROMPT --LATCH HIT
set lines 155
set pagesize 400

SELECT (1 - (Sum(misses) / Sum(gets))) * 100 "LATCH HIT" FROM v$latch;

PROMPT
PROMPT --UTILIZACAO BUFFER CACHE

set lines 80

column "col1"  format a25  		heading "BLOCOS BUFFER CACHE"
column "col2"  format 99,999,999,990  	heading "Quantidade"
column "col3"  format 99,999,999,990  	heading "TOTAL"

select 
	decode(state,	0,'Nao Usado',
			1,'Lido e Modificado',
			2,'Lido e nao Modificado',
			3,'Lido Correntemente',
		  	'Outros')			"col1",
	count(*)					"col2"
from 
	x$bh
group by
	decode(state, 0,'Nao Usado',
			1,'Lido e Modificado',
			2,'Lido e nao Modificado',
			3,'Lido Correntemente',
		  	'Outros')
;

PROMPT
PROMPT --Shared Pool Utilizada

set serveroutput on;  
  
declare  
        object_mem number;  
        shared_sql number;  
        cursor_mem number;  
        mts_mem number;  
        used_pool_size number;  
        free_mem number;  
        pool_size varchar2(512); -- same as V$PARAMETER.VALUE  
begin  
  
-- Stored objects (packages, views)  
select sum(sharable_mem) into object_mem from v$db_object_cache;  
-- User Cursor Usage -- run this during peak usage.  
--  assumes 250 bytes per open cursor, for each concurrent user.  
select sum(250*users_opening) into cursor_mem from v$sqlarea;  
  
-- For a test system -- get usage for one user, multiply by # users  
-- select (250 * value) bytes_per_user  
-- from v$sesstat s, v$statname n  
-- where s.statistic# = n.statistic#  
-- and n.name = 'opened cursors current'  
-- and s.sid = 25;  -- where 25 is the sid of the process  
  
-- MTS memory needed to hold session information for shared server users  
-- This query computes a total for all currently logged on users (run  
--  during peak period). Alternatively calculate for a single user and  
--  multiply by # users.  
select sum(value) into mts_mem from v$sesstat s, v$statname n  
       where s.statistic#=n.statistic#  
       and n.name='session uga memory max';  
  
-- Free (unused) memory in the SGA: gives an indication of how much memory  
-- is being wasted out of the total allocated.  
select bytes into free_mem from v$sgastat  
        where name = 'free memory' and pool='shared pool';  
-- For non-MTS add up object, shared sql, cursors and 30% overhead.  
used_pool_size := round(1.3*(object_mem+cursor_mem));  
  
-- For MTS mts contribution needs to be included (comment out previous line)  
-- used_pool_size := round(1.3*(object_mem+shared_sql+cursor_mem+mts_mem));  
  
select value into pool_size from v$parameter where name='shared_pool_size';  
  
-- Display results  
dbms_output.put_line ('Object mem:    '||to_char (object_mem) || ' bytes');  
dbms_output.put_line ('Cursors:       '||to_char (cursor_mem) || ' bytes');  
-- dbms_output.put_line ('MTS session:   '||to_char (mts_mem) || ' bytes');  
dbms_output.put_line ('Free memory:   '||to_char (free_mem) || ' bytes ' ||  
'('|| to_char(round(free_mem/1024/1024,2)) || 'MB)');  
dbms_output.put_line ('Shared pool utilization (total):  '||  
to_char(used_pool_size) || ' bytes ' || '(' ||  
to_char(round(used_pool_size/1024/1024,2)) || 'MB)');  
dbms_output.put_line ('Shared pool allocation (actual):  '|| pool_size 
||' bytes ' || '(' || to_char(round(pool_size/1024/1024,2)) || 'MB)');  
dbms_output.put_line ('Percentage Utilized:  '||to_char  
(round(used_pool_size/pool_size*100)) || '%');  
end;  
/

PROMPT
PROMPT --Pools Livres na SGA

col mb_free for 999,999,999.999
select initcap(pool) pool, bytes/1024/1024 mb_free
from   v$sgastat
where  name = 'free memory'
/

PROMPT
PROMPT --Parse
set lines 155
select
  to_char(100 * sess / calls, '999999999990.00') || '%' cursor_cache_hits,
  to_char(100 * (calls - sess - hard) / calls, '999990.00') || '%' soft_parses,
  to_char(100 * hard / calls, '999990.00') || '%' hard_parses
from
  ( select value calls from v$sysstat where name = 'parse count (total)' ),
  ( select value hard  from v$sysstat where name = 'parse count (hard)' ),
 ( select value sess  from v$sysstat where name = 'session cursor cache hits' )
/

PROMPT
PROMPT --Cursores Abertos

select count(*) "Cursor Abertos"
from v$session a, v$sesstat b, v$statname c 
where b.sid = a.sid 
and c.statistic# = b.statistic# 
and c.name = 'opened cursors current';

PROMPT
PROMPT --Quantidade de Parse x Cursores

select a.sid, a.value parse_total, 
	(select x.value 
		from v$sesstat x, v$statname y 
		where x.sid = a.sid 
		and y.statistic# = x.statistic# 
		and y.name = 'session cursor cache hits'
	) cache_total 
from v$sesstat a, v$statname b 
where b.statistic# = a.statistic# 
and b.name = 'parse count (total)' 
and value > 0;

PROMPT
select sum(cache_total) "Total Cache", sum(parse_total) "Total Parse" from 
	(
	select a.sid, a.value parse_total, 
		(select x.value 
			from v$sesstat x, v$statname y 
			where x.sid = a.sid 
			and y.statistic# = x.statistic# 
			and y.name = 'session cursor cache hits'
		) cache_total 
	from v$sesstat a, v$statname b 
	where b.statistic# = a.statistic# 
	and b.name = 'parse count (total)' 
	and value > 0
	);

PROMPT
PROMPT --Memoria na Execucao de SQL - Processos

column "col1"  format 999,999,999,990  heading "PGA Usada Correntemente"
column "col2"  format 999,999,999,990  heading "PGA Alocada Correntemente"
column "col3"  format 999,999,999,990  heading "PGA Maxima Alocada"

select 	
	sum (pga_used_mem)	"col1",
	sum (pga_alloc_mem)	"col2",
	sum (pga_max_mem)	"col3"
from 
	v$process
;

PROMPT
PROMPT --Memoria PGA Usada - Livre

set serveroutput on

declare

v_free number;
v_used number;
v_target number;

begin

select nvl(a.value/1024/1024,0), nvl(a.value/1024/1024 - b.value/1024/1024,0), nvl(b.value/1024/1024,0) into v_target, v_used, v_free
from v$pgastat a, v$pgastat b
where a.name = 'aggregate PGA target parameter'
and b.name = 'total freeable PGA memory';

dbms_output.put_line('Memória PGA: '||trunc(v_target));
dbms_output.put_line('Memória PGA Usada: '||round(v_used));
dbms_output.put_line('Memória PGA Livre: '||round(v_free));

end;
/

PROMPT 
PROMPT --Memoria na Execucao de SQL - Estatisticas

column "col1"  format a35  	    heading "Estatistica"
column "col2"  format 999,999,999,990 heading "Valor"

select 	
	name 	"col1", 
	value	"col2"
from 		
	v$sysstat
where
	name LIKE '%workarea%'
;

PROMPT 
PROMPT --Workareas com maior consumo de memoria

set lines 155

column "col1"  format 999999999  		heading "Workarea"
column "col2"  format a18			heading "Operacao"
column "col3"  format a6			heading "Polit."
column "col4"  format 999,999,999		heading "Tamanho em KB|para execucao|em memoria"
column "col5"  format 99,999		heading "Nro de|vezes|ficou|Ativa"
column "col6"  format 99,999		heading "Nro de|vezes|rodou|Optimal"
column "col7"  format 99,999		heading "Nro de|vezes|rodou|One-pass"
column "col8"  format 99,999	        heading "Nro de|vezes|rodou|Multi-pass"
column "col9"  format 999,999,999,999	heading "Media|tempo|Ativa|cent/segs"

select 	*
from 	(select	workarea_address 	"col1",
		operation_type		"col2",
		policy			"col3",
		estimated_optimal_size	"col4",
		total_executions	"col5",
		optimal_executions	"col6",
		onepass_executions	"col7",
		multipasses_executions	"col8",
		active_time		"col9"
	 from 	v$sql_workarea
	 order by estimated_optimal_size desc)
where	rownum <= 10 ;

PROMPT 
PROMPT --Advisors 1 - Buffer Cache, 2 - Shared Pool, 3 - PGA, 4 - SGA, 5 - MEMORY (11g)
set lines 400;
SELECT SIZE_FOR_ESTIMATE, SIZE_FACTOR, ESTD_PHYSICAL_READ_FACTOR FROM V$DB_CACHE_ADVICE ORDER BY 1;

PROMPT 
SELECT SHARED_POOL_SIZE_FOR_ESTIMATE, SHARED_POOL_SIZE_FACTOR, ESTD_LC_TIME_SAVED, ESTD_LC_SIZE FROM V$SHARED_POOL_ADVICE ORDER BY 1;

PROMPT 
SELECT PGA_TARGET_FACTOR, PGA_TARGET_FOR_ESTIMATE, ESTD_PGA_CACHE_HIT_PERCENTAGE, ESTD_EXTRA_BYTES_RW, ESTD_OVERALLOC_COUNT FROM V$PGA_TARGET_ADVICE ORDER BY 1;

PROMPT 
SELECT * FROM v$sga_target_advice ORDER BY sga_size;

PROMPT 
SELECT * FROM v$memory_target_advice ORDER BY memory_size;

PROMPT
PROMPT >>>>>>>> TOP SESSION
set linesize 1000
set pagesize 1000
set long 1000000

select SQL_HASH_VALUE, SQL_ADDRESS,  SID, SERIAL#, USERNAME, OSUSER, MACHINE, MODULE, PROGRAM, TIME_COMMAND, TIMESTAMP, SQL_TEXT
from TEIKOADM.TK_VW_TOP_SQLTEXT_MR
where TO_CHAR(TIMESTAMP, 'HH24') BETWEEN (select SUBSTR(VALUE, 1, 2) from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 26) 
AND (select SUBSTR(VALUE, 4, 2) from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 26) 
AND TO_CHAR(TIMESTAMP, 'D') NOT IN (1, 7) AND TO_CHAR(TIMESTAMP, 'YYYYMM') = TO_CHAR(SYSDATE-30,'YYYYMM') 
AND ROWNUM < 10 ORDER BY TIME_COMMAND DESC;

PROMPT
PROMPT >>>>>>>> TOP FULLSCAN

select SQL_ADDRESS,  SID, SERIAL#, USERNAME, OSUSER, EVENT, MODULE, PROGRAM, LAST_CALL_ET, TIMESTAMP, SQL_TEXT from TEIKOADM.TK_VW_FULL_SCAN_SQLTEXT_MR
where TO_CHAR(TIMESTAMP, 'HH24') BETWEEN
(select SUBSTR(VALUE, 1, 2)
from TEIKOADM.TK_ENVIRONMENT_PARAMETERS
where ID_PARAMETER = 26) and
(select SUBSTR(VALUE, 4, 2)
from TEIKOADM.TK_ENVIRONMENT_PARAMETERS
where ID_PARAMETER = 26)
AND TO_CHAR(TIMESTAMP, 'D') NOT IN (1, 7)
AND LAST_CALL_ET > (select VALUE from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 40)
AND TO_CHAR(TIMESTAMP, 'YYYYMM') = TO_CHAR(SYSDATE-30,'YYYYMM')
AND SQL_TEXT IS NOT NULL
ORDER BY LAST_CALL_ET DESC;

PROMPT
PROMPT >>>>>>>> ESTATISTICA UNDO

set long 1
set lines 155
set pagesize 400

col b_time for a20
col e_time for a20

compute sum of undoblks on report
compute sum of mb       on report
break on report

SELECT to_char(begin_time,'dd/mm/yyyy hh24:mi:ss') b_time,
       to_char(end_time,  'dd/mm/yyyy hh24:mi:ss') e_time,
       undoblks,
       undoblks*value/1024/1024                    mb
FROM   v$undostat, v$parameter
where name = 'db_block_size'
/

PROMPT

select * from 
(
	select class, count waits from v$waitstat where class in 
		('system undo header', 'system undo block', 'undo header', 'undo block')
),
(
	select sum(value) total_number_of_requests from v$sysstat where name in 
		('db_block_gets', 'consistent gets')
);

PROMPT

column "col1"  format a14  		heading "Intervalo"
column "col2"  format 999,999		heading "Blocos    |Consumidos"
column "col3"  format 999,999		heading "Transacoes  |Concorrentes"
column "col4"  format 999,999,999,999	heading "Transacoes|Periodo   "
column "col5"  format 999,999		heading "Tempo Execucao|Query         "
column "col6"  format 999,999		heading "Extents    |Emprestados"
column "col7"  format 999,999		heading "ora1555"

select 
	to_char(end_time,'dd/mm/yy hh24:mi')		"col1",
	undoblks					"col2",	
	maxconcurrency				"col3",
	txncount					"col4",
	maxquerylen					"col5",
	expblkrelcnt				"col6",
	ssolderrcnt					"col7"
from 
	v$undostat
;

PROMPT
PROMPT >>>>>>>> SORT

set lines 80

column "col1" format a70 

select 
	initcap(rpad(name,30,' ')||' = '||
	rpad(to_char(value,'999,999,999,990'),30,' ')) "col1"
from
	v$sysstat
where
	name in ('sorts (memory)','sorts (disk)')
;

column "col1" format 0.99 heading "SORT RATIO"

select 
	decode(b.value,0,0,((b.value / a.value) * 100))      "col1"
from
	v$sysstat a ,
	v$sysstat b
where
	a.name = 'sorts (memory)'	and
	b.name = 'sorts (disk)'
;

--PROMPT
--PROMPT FREE LIST -> USADO EM 9i
--set lines 80

--select 
--	initcap(rpad(class,9,' ')||' = '||
--	rpad(to_char(count,'999,990'),8,' ')) "col1"
--from
--	v$waitstat
--where
--	class = 'free list'
--;

PROMPT
PROMPT >>>>>>>> DBWR WORKLOAD (OBS: Este indicador é apenas para 10g e não para 11g, Para Bancos com 11g não precisa colocar o mesmo)

set lines 80
set heading off

select 
	'REQUISICOES DBWR PARA BUFFER LIVRE PARA LRU'||' '||' = '||
	to_char(value,'99,999,999,990') "col1"
from
	v$sysstat
where
	name = 'DBWR make free requests'
;

set heading on

--PROMPT
--PROMPT REDO LOG BUFFER

--PROMPT -- Quantidade de Requisicoes no Log Buffer
--set lines 80

--select 
--	'ESPERA POR ESPACO NO REDO LOG BUFFER = '||
--	rpad(to_char(value,'999,999,990'),12,' ')
--from
--	v$sysstat
--where
--	name = 'redo log space requests'
--;

--PROMPT
--PROMPT -- Tempo de Espera por Espaço no Log Buffer
--SELECT 'TEMPO DE ESPERA POR ESPACO NO REDO LOG BUFFER = ' || rpad(to_char(VALUE/100,'999,999,990'),12,' ') as "TIME WAIT IN LOG BUFFER"
--FROM V$SYSSTAT
--WHERE NAME = 'redo log space wait time';

PROMPT
PROMPT >>>>>>>> REDO LOG BUFFER (WAIT)

set lines 155
set pages 500

column "col1" heading "Evento" format a50	
column "col2" heading "Número Esperas" format 99,999,999,999
column "col3" heading "Média ESPERA (S)" format 99,999.90

select 
	event           		     "col1" ,
	sum(total_waits)		     "col2" , 	
	avg(average_wait)/100		 "col3" 
from
	v$system_event
where
	average_wait > 0
and event in 
(
	'Log archive I/O','log buffer space','log file sync','log file parallel write','log file sequential read','log file single write'
	,'Log file init write','log file switch (archiving needed)','log file switch (checkpoint incomplete)','log file switch (clearing log file)'
    ,'log file switch completion','log file switch (private strand flush incomplete)','log switch/archive','log write(even)','log write(odd)'
)
group by event
order by 3 desc
;

PROMPT
PROMPT >>>>>>>> REDO LOG

set lines 155

column "col1"  format 999		heading "Grp"
column "col2"  format a37  		heading "Nome do Membro"
column "col3"  format a16  		heading "Status"
column "col4"  format a16  		heading "Archived"
column "col5"  format 999,999,999  	heading "Tamanho"

select 
	b.group#						"col1",	
	b.member						"col2",	
	decode(b.status,null,a.status,b.status||' '||a.status)	"col3",
	a.archived                      "col4",
	a.bytes							"col5"
from 	
	sys.v$log 	a ,
	sys.v$logfile	b
where
	a.group# = b.group#	
order by 
	b.group#
;

PROMPT
PROMPT >>>>>>>> PARAMETRO CHECKPOINT
show parameter checkpoint

PROMPT
PROMPT >>>>>>>> CHECKPOINT, DATAFILE HEADER

select status, checkpoint_change#, fuzzy,
       to_char(checkpoint_time, 'DD-MM-YYYY HH24:MI:SS') as checkpoint_time, 
       count(*) 
from V$DATAFILE_HEADER 
group by status, checkpoint_change#, fuzzy, checkpoint_time 
order by status, checkpoint_change#, fuzzy, checkpoint_time;

PROMPT
PROMPT >>>>>>>> CONTROLFILE

set lines 155
col name for a70

select name, status, is_recovery_dest_file from v$controlfile;

PROMPT
PROMPT >>>>>>>> PARAMETROS ALTERADOS

--Parametros Alterados no Banco de Dados
alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';

col "Nome Parametro" format a25
col "Instancia" format a10
col "Valor Atual" format a32

select a.instance_name "Instancia",
       a.name          "Nome Parametro",
       a.value         "Valor Atual",
       --'      '        "Valor Anterior",
       a.timestamp     "Data Alteracao"
  from teikoadm.tk_parameters_hist a
 where to_char(timestamp,'MMYYYY') = to_char(sysdate-30,'MMYYYY')
 order by timestamp;
 
PROMPT
PROMPT >>>>>>>> EVENTOS

set lines 80
set pages 500

column "col1" heading "Evento" format a30	
column "col2" heading "Numero de Esperas" format 99,999,999,999
column "col3" heading "MEDIA de ESPERA" format 99,999.90

select 
	substr(event,1,30) 		     "col1" ,
	sum(total_waits)		     "col2" , 	
	avg(average_wait)/100		 "col3" 
from
	v$system_event
where
	average_wait > 0
group by event
order by 3 desc
; 
 
PROMPT
PROMPT >>>>>>>> I/O

set pages 100
set lines 100

column "col1"  format a45		    heading "Nome do Data File" 	word_wrapped
column "col2"  format 999,999,990	    heading "Blocos      |Fisicos     "
column "col3"  format 999,999,990	    heading "Leituras    |Fisicas     "
column "col4"  format 999,999,990	    heading "Gravacoes   |Fisicas     "
column "col5"  format 999,999,990     heading "Total       |de I/O      "

select 
	a.name				     "col1" , 	
	b.phyblkrd       		     "col2" , 	
	b.phyrds       			     "col3" , 	
	b.phywrts			     "col4" ,	
	b.phyrds+b.phywrts		     "col5" 	
from
	v$datafile a,
	v$filestat b
where
	a.file#=b.file#
order by 1
;

column "col1"  format a45		    heading "Nome do Temp File" 	word_wrapped

select 
	a.name				     "col1" , 	
	b.phyblkrd       		     "col2" , 	
	b.phyrds       			     "col3" , 	
	b.phywrts			     "col4" ,	
	b.phyrds+b.phywrts		     "col5" 	
from
	v$tempfile a,
	v$tempstat b
where
	a.file#=b.file#
order by 1
;

column "col1"  format a45		    heading "Nome do Data File" 	word_wrapped
column "col2"  format 990.99	    heading "I/O's|(Seg)"

select 
	a.name				     									"col1", 
	(b.phyrds+b.phywrts) / 	
	        (24 * 3600 * (to_date(to_char(sysdate,'dd-mm-yy hh24:mi:ss'), 'dd-mm-yy hh24:mi:ss') - 
	  	              to_date(to_char(c.startup_time,'dd-mm-yy hh24:mi:ss'), 'dd-mm-yy hh24:mi:ss')))	"col2"
from
	v$datafile a,
	v$filestat b,
	v$instance c
where
	a.file#=b.file#
order by 1
;

column "col1"  format a45		    heading "Nome do Temp File" 	word_wrapped

select 
	a.name				     									"col1", 
	(b.phyrds+b.phywrts) / 	
	        (24 * 3600 * (to_date(to_char(sysdate,'dd-mm-yy hh24:mi:ss'), 'dd-mm-yy hh24:mi:ss') - 
	  	              to_date(to_char(c.startup_time,'dd-mm-yy hh24:mi:ss'), 'dd-mm-yy hh24:mi:ss')))	"col2"
from
	v$tempfile a,
	v$tempstat b,
	v$instance c
where
	a.file#=b.file#
order by 1
;
 
PROMPT
PROMPT >>>>>>>> OBJETOS QUE NECESSITAM DE REORGANIZAÇÃO
PROMPT
--set lines 500

--column "col1"  format a22		heading "Tablespace"	word_wrapped
--column "col2"  format 999  		heading "Data File"
--column "col3"  format 99990  		heading "Fragmentos do|Data File    "
--column "col4"  format 999,999,999,990	heading "Maior Area Livre |Contigua (Bytes)"
--column "col5"  format 999,999,999,990 	heading "Area Livre    |Total (Bytes)"
--column "col6"  format 999,999,999,990	heading "MegaBytes Total"

--select 
--	tablespace_name 	"col1",	
--	file_id 		"col2",
--	count(*) 		"col3",
--	max(bytes) 		"col4",
--	sum(bytes) 		"col5"
--from 	
--	sys.dba_free_space
--group by 
--	tablespace_name,
--	file_id
--order by 2
--;

set serveroutput on
declare
cursor c_task
is
	select task_name, status, created
	from dba_advisor_tasks 
	where owner = 'SYS' 
	and advisor_name = 'Segment Advisor' 
	and task_id = (select max(task_id) from dba_advisor_tasks where advisor_name = 'Segment Advisor')
	order by 3 DESC;

reg_c_task c_task%rowtype;	
v_segname CHAR;
v_type    CHAR;
v_message CLOB;
v_c NUMBER;
i NUMBER;
begin
open c_task;
		loop
			fetch c_task into reg_c_task;
			exit when c_task%notfound;			
				declare
				crlf                varchar2(2):= chr(13)||chr(10);
				cursor c_segment is
					select ao.attr2, ao.type, af.message
						from dba_advisor_findings af, dba_advisor_objects ao
							where ao.task_id = af.task_id
							and ao.object_id = af.object_id
							and ao.owner = 'SYS' and
							af.task_name=reg_c_task.task_name
							order by 2 ASC ,1 ASC;
				reg_c_segment c_segment%rowtype;
				begin
					open c_segment;
					loop
						fetch c_segment into reg_c_segment;
						exit when c_segment%notfound;						
						DBMS_OUTPUT.PUT_LINE('SEGNAME: '||reg_c_segment.attr2||crlf||
											 'TYPE: '||reg_c_segment.type||crlf||
											 'Message: '||reg_c_segment.message||crlf);
					end loop;
					close c_segment;
				end;
		end loop;
close c_task;			
end;
/

PROMPT 
PROMPT >>>>>>>> TAMANHO TABLESPACE
set linesize 100
set pagesize 400
set long 1
select 
	tablespace_name
	, count(*) "QTDDE DBF"
	, sum(bytes/1024/1024/1024) B_GB
	, sum(maxbytes/1024/1024/1024) MB_GB
	, to_char(((sum(bytes/1024/1024/1024))*100/(sum(maxbytes/1024/1024/1024))),'99.99') ||'%' as "% Usado"
from dba_data_files 
where tablespace_name not in ('TEIKOTSTBACKUP')
group by rollup(tablespace_name)
union all
select 
	tablespace_name
	, count(*) "QTDDE DBF"
	, sum(bytes/1024/1024/1024) B_GB
	, sum(maxbytes/1024/1024/1024) MB_GB
	, to_char(((sum(bytes/1024/1024/1024))*100/(sum(maxbytes/1024/1024/1024))),'99.99') ||'%' as "% Usado"
from dba_temp_files 
where tablespace_name not in ('TEIKOTSTBACKUP')
group by rollup(tablespace_name)
order by 1 ASC;

PROMPT
PROMPT ASM

set lines 155
set pagesize 1000
col NAME for a11
col "DISK NAME" for a12

select 
	a.GROUP_NUMBER, a.NAME, a.TOTAL_MB, a.FREE_MB, to_char((100-(a.FREE_MB * 100 /a.TOTAL_MB)),'99.99') "PCT USED" , 
	a.OFFLINE_DISKS, a.STATE 
from v$asm_diskgroup a 
	where a.TOTAL_MB > 0;

select 
	a.NAME, b.TOTAL_MB, b.FREE_MB, b.NAME "DISK NAME", b.READS, 
	b.WRITES, b.BYTES_READ/1024/1024/1024 READS_GB, b.BYTES_WRITTEN/1024/1024/1024 WRITES_GB 
from v$asm_diskgroup a join v$asm_disk b 
	on(a.GROUP_NUMBER=b.GROUP_NUMBER);

PROMPT
PROMPT >>>>>>>> OBJETOS INVALIDOS

set pagesize 1000
set linesize 300
column "col1"  format a20	heading "SCHEMA"
column "col2"  format a20  	heading "NOME OBJETO"
column "col3"  format a23  	heading "STATUS"
select 
	owner		"col1",
	object_name		"col2",
	status	"col3"
from 	
	dba_objects
where 
	status != 'VALID'
;

PROMPT

set pagesize 1000
set linesize 300
column "col1"  format a30	heading "OWNER"
column "col2"  format a20  	heading "TIPO OBJETO"

select 
	owner		    "col1",
	object_type		"col2",
	count(*)	    "QUANT"
from 	
	sys.dba_objects
where 
	status != 'VALID'
	--and object_type = 'SYNONYM'
	--and object_name not in ('BOLLOJABRAND','MSISCONECTA')
group by owner, object_type;
	
/*------------------------------------------------------------------------------------

set serveroutput on

declare
	cursor c_cursor is 
		select 
			owner		    "col1",
			object_type		"col2",
			count(*)	    "QUANT"
		from 	
			sys.dba_objects
		where 
			status != 'VALID'
			and object_type = 'SYNONYM'
		group by 
			owner, object_type;
	
reg_cursor c_cursor%rowtype;
c number;

begin
c:=0;
open c_cursor;
	loop
		fetch c_cursor into reg_cursor;
		exit when c_cursor%notfound;
		
		c := c + reg_cursor.QUANT;
		
	end loop;
		DBMS_OUTPUT.PUT_LINE(c);
close c_cursor;

end;
/

-------------------------------------------------------------------------------------*/
	
PROMPT
PROMPT -- Recyclebin
column "col1" format a10   heading "Usuario"
column "col2" format a35   heading "Nome Objeto"
column "col3" format a26   heading "Nome Original"
column "col4" format a14   heading "Tipo"
column "col5" format a15   heading "Tablespace"
column "col7" format a20   heading "Criacao"
column "col8" format a20   heading "Drop"

SELECT 
  OWNER "col1"
, OBJECT_NAME "col2"
, ORIGINAL_NAME "col3"
, TYPE "col4"
, TS_NAME "col5"
, SPACE "Espaco"
, CREATETIME "col7"
, DROPTIME "col8"
FROM DBA_RECYCLEBIN;

PROMPT
PROMPT >>>>>>>> SEGURANCA (ROLE DBA PARA USUARIOS)

set linesize 100
set pages 1000

column "col1"  format a30	heading "Usuário"

select 
	grantee 	"col1"
from 
	dba_role_privs
where 
	granted_role = 'DBA'
and grantee not in (select role from dba_roles) 
;

PROMPT
PROMPT >>>>>>>> USUARIOS
set lines 155
set pagesize 400

select USERNAME, ACCOUNT_STATUS from dba_users;

PROMPT
PROMPT >>>>>>>> QUANTIDADE DE ARCHIVES GERADOS POR HORA (Válido apenas se o parâmetro archive_lag_target estiver com 0)

alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';

select trunc(FIRST_TIME,'hh') data_hora,count(*) qtd, sum(blocks*block_size/1024/1024) mb
from v$archived_log
where to_char(trunc(FIRST_TIME,'hh'),'YYYYMM') = to_char(sysdate-30,'YYYYMM')
group by trunc(FIRST_TIME,'hh')
order by trunc(FIRST_TIME,'hh');

PROMPT
PROMPT -- Volume Archivelog

column mb format 999,999,990.000
select trunc(first_time,'hh') horario, sum(blocks*block_size/1024/1024) mb
from v$archived_log
group by trunc(first_time,'hh')
order by 1;

PROMPT
PROMPT >>>>>>>> QUANTIDADE DE JOBS DUPLICADOS
set lines 400
alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';
col WHAT for a50
col SCHEMA_USER for a5
col INTERVAL for a26
select WHAT, schema_user, INTERVAL, BROKEN, FAILURES, count(*)
from dba_jobs 
group by WHAT, schema_user, INTERVAL, BROKEN, FAILURES
having count(*) > 1
order by 3;

PROMPT
PROMPT >>>>>>>> JOBS QUEBRADOS / FALHADOS
set lines 400
set pages 1000
col WHAT for a47
col SCHEMA_USER for a20
PROMPT--BROKEN
select schema_user, job, broken, failures, what from dba_jobs where broken='Y';
PROMPT--FAILURES
select schema_user, job, failures, what from dba_jobs where failures>0;

PROMPT
PROMPT >>>>>>>> JOBS PURGE_LOG

set lines 155
set pagesize 1000
col owner for a15
col LAST_START_DATE for a30
col NEXT_RUN_DATE for a30
col LAST_RUN_DURATION for a30
col START_DATE for a30
col END_DATE for a30

select OWNER, JOB_NAME, START_DATE, END_DATE, LAST_START_DATE, NEXT_RUN_DATE, LAST_RUN_DURATION from dba_scheduler_jobs where JOB_NAME='PURGE_LOG';

select STATE, MAX_FAILURES, MAX_RUNS, FAILURE_COUNT from dba_scheduler_jobs where JOB_NAME='PURGE_LOG';

PROMPT
PROMPT >>>>>>>> VERIFICA SE HÁ MAIS DE UMA SESSAO DA MESMA MAQUINA E MESMO USUARIO

set lines 400
set pages 1000
col MACHINE for a23
col USERNAME for a15
col OSUSER for a16
col PROGRAM for a20
select USERNAME, OSUSER, MACHINE, PROGRAM, count(*) "INATIVO"		
					from v$session where status!='ACTIVE'
						group by USERNAME, OSUSER, MACHINE, PROGRAM
							having count(*) > 1
							order by 5 DESC, 2 ASC;
							
select USERNAME, OSUSER, MACHINE, PROGRAM, count(*) "ATIVO"		
					from v$session where status='ACTIVE'
						group by USERNAME, OSUSER, MACHINE, PROGRAM
							having count(*) > 1
							order by 5 DESC, 2 ASC;
							

PROMPT
PROMPT >>>>>>>> RESOURCE LIMIT

SET LINES 999 PAGES 1000

select *
from v$resource_limit
where resource_name in ('processes','sessions','transactions','enqueue_resources')
/



PROMPT 
PROMPT ---------------------------------------------------------------------------------------------------------------------------------
spool off
disc
exit

