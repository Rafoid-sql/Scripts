-- ver tamanho total fisico do BD, considerando datafiles, tempfiles e logs
Select  round(sum(used.bytes) / 1024 / 1024/1024 ) || ' GB' "Database Size",
        round(free.p / 1024 / 1024/1024) || ' GB' "Free space"
from    (select bytes from v$datafile
          union all
         select bytes from v$tempfile
          union all
          select bytes from v$log) used,   
    (select sum(bytes) as p from dba_free_space) free
group by free.p;

-- ver tamanho total logico do BD:
select (sum(bytes)/1024/1024/1024) as Logical_size_gb from dba_segments;

-- ver tamanho total logico somente tabelas:
select (sum(bytes)/1024/1024/1024) as Table_Size_gb from dba_segments where segment_type in ('TABLE SUBPARTITION','TABLE PARTITION','TABLE');

-- ver tamanho total logico somente indices:
select (sum(bytes)/1024/1024/1024) as Index_Size_gb from dba_segments where segment_type in ('INDEX PARTITION','INDEX');

-- ver tamanho total logico somente lob:
select (sum(bytes)/1024/1024/1024) as Lob_size_gb from dba_segments where SEGMENT_TYPE='LOBSEGMENT';

	
-- Ver tamanho por segmentos
select segment_type, (sum(bytes)/1024/1024/1024) as Size_GB from dba_segments 
       where segment_type in ('TABLE','INDEX','LOBSEGMENT','LOBINDEX')group by(segment_type) order by 2 desc;
  


	column used.bytes format 99999999999 
	select sum(used.bytes)/30000
	 from (select bytes from v$datafile
          union all
         select bytes from v$tempfile
          union all
          select bytes from v$log) used;
		  
		  
		  max(bytes)/1024 largest
		  
		 
-- Tamanho de TABLESPACE
		 
  	set linesize 200
	set pagesize 200
	col name format a20
	col segment_management for a20
	col pct_free for a20
	column total_bytes format 9999999999999
	column used format 9999999999999
	column pct_free format 9999999999999
	 
	select (select tablespace_name
	from dba_tablespaces
	where tablespace_name = b.tablespace_name
	) name
	,round(kbytes_alloc*1024, 2) total_bytes
	,round((kbytes_alloc-nvl(kbytes_free,0))*1024, 2) used
	,round(((nvl(kbytes_free,0))/ kbytes_alloc)*100, 2) pct_free
	from (select sum(bytes)/1024 Kbytes_free,  tablespace_name
	from sys.dba_free_space
	group by tablespace_name ) a
	,(select sum(bytes)/1024 Kbytes_alloc, sum(maxbytes)/1024 Kbytes_max, tablespace_name
	from sys.dba_data_files
	group by tablespace_name
	union all
	select sum(bytes)/1024 Kbytes_alloc, sum(maxbytes)/1024 Kbytes_max, tablespace_name
	from sys.dba_temp_files group by tablespace_name )b
	where a.tablespace_name (+) = b.tablespace_name
	and b.tablespace_name = '&tablespace_name';
	

-- Tamanho dos DGs

set lines 155
set pagesize 100
col NAME for a15
col PCT_FREE for a15
column Total_Bytes format 999999999999999
column Used_Bytes format 999999999999999



select 
	a.NAME, a.TOTAL_MB*1024*1024 as Total_Bytes  
	from v$asm_diskgroup a 
	where a.TOTAL_MB > 0
	and a.NAME = 'DGDATA';
	
	


	select 
		a.NAME, ((a.TOTAL_MB-a.FREE_MB)*1024*1024) as Used_Bytes  
		from v$asm_diskgroup a 
		where a.TOTAL_MB > 0
		and a.NAME = 'DGDATA';
	
	
	
	


select 
	a.NAME, to_char(((a.FREE_MB * 100 /a.TOTAL_MB)),'99.99') "PCT_FREE"  
	from v$asm_diskgroup a 
	where a.TOTAL_MB > 0
	and a.NAME = 'DGDATA';
	