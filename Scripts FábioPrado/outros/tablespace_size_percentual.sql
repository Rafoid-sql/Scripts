set linesize 100
set pagesize 400
set long 1
select 
	tablespace_name
	, count(*) "QTDDE DBF"
	, sum(bytes/1024/1024) B_GB
	, sum(maxbytes/1024/1024) MB_GB
	, to_char(((sum(bytes/1024/1024))*100/(sum(maxbytes/1024/1024))),'99.99') ||'%' as "% Usado"
from dba_data_files 
where tablespace_name not in ('TEIKOTSTBACKUP')
group by rollup(tablespace_name)
union all
select 
	tablespace_name
	, count(*) "QTDDE DBF"
	, sum(bytes/1024/1024) B_GB
	, sum(maxbytes/1024/1024) MB_GB
	, to_char(((sum(bytes/1024/1024))*100/(sum(maxbytes/1024/1024))),'99.99') ||'%' as "% Usado"
from dba_temp_files 
where tablespace_name not in ('TEIKOTSTBACKUP')
group by rollup(tablespace_name)
order by 1 ASC;
	
	
	=======================
	
set lines 155
set pagesize 200
SELECT      d.tablespace_name "Name",
            d.status "Status",
            a.bytes/ 1024 / 1024 "TOTAL(M)",
            F.bytes / 1024 / 1024 "LIVRE(M)",
            ((a.bytes - DECODE(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024) "ALOCADO(M)",
            d.block_size
FROM        sys.dba_tablespaces d,
            sys.sm$ts_avail a,
            sys.sm$ts_free f
WHERE       d.tablespace_name = a.tablespace_name
AND         f.tablespace_name (+) = d.tablespace_name
ORDER BY    3 DESC;
	
	
-- disk asm usado
	
select name, total_mb, free_mb, round((free_mb/total_mb)*100,2) "% FREE", 100-round((free_mb/total_mb)*100,2) "% Usado"
 from v$asm_diskgroup;
 
	
--resize

 select 'alter database datafile ''' || file_name || ''' resize ' ||
 ceil( (nvl(hwm,1)*8192)/1024/1024+1 )|| 'm;' smallest,
 ceil( blocks*8192/1024/1024) currsize,
 ceil( blocks*8192/1024/1024) -
 ceil( (nvl(hwm,1)*8192)/1024/1024 ) savings
 from dba_data_files a,
 ( select file_id, max(block_id+blocks-1) hwm
 from dba_extents where tablespace_name in ('ACADEMICO','ACADEMICO_BLOB')
 group by file_id ) b
 where a.file_id = b.file_id(+)
 --and tablespace_name in ('ACADEMICO','ACADEMICO_BLOB')
 order by savings
 /
	
-- Tamanho do database
	
	SELECT 'Database Tamanho' "*****"
,ROUND(SUM(ROUND(SUM(NVL(fs.bytes/1024/1024,0)))) /
SUM(ROUND(SUM(NVL(fs.bytes/1024/1024,0))) + ROUND(df.bytes/1024/
1024 - SUM(NVL(fs.bytes/1024/1024,0)))) * 100, 0) "%Livre"
,ROUND(SUM(ROUND(df.bytes/1024/1024 - SUM(NVL(fs.bytes/1024/
1024,0)))) / SUM(ROUND(SUM(NVL(fs.bytes/1024/1024,0))) +
ROUND(df.bytes/1024/1024 - SUM(NVL(fs.bytes/1024/1024,0)))) * 100,
0) "%Usado"
,SUM(ROUND(SUM(NVL(fs.bytes/1024/1024/1024,0)))) "GB Livre"
,SUM(ROUND(df.bytes/1024/1024/1024
- SUM(NVL(fs.bytes/1024/1024/1024,0)))) "GB Usado"
,SUM(ROUND(SUM(NVL(fs.bytes/1024/1024/1024,0))) + ROUND(df.bytes/1024/
1024/1024
- SUM(NVL(fs.bytes/1024/1024/1024,0)))) "Tamanho em GB"
FROM dba_free_space fs, dba_data_files df
WHERE fs.file_id(+) = df.file_id
GROUP BY df.tablespace_name, df.file_id, df.bytes,
df.autoextensible
ORDER BY df.file_id ;