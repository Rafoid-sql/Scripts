set linesize 100
set pagesize 300
set long 1
select 
	decode (grouping(tablespace_name),1, 'xTOTAL DATAFILES',tablespace_name) "TABLESPACE",
    count(*) "QTDE",
	sum(maxbytes/1048576) "TOTAL_GB",
	sum(bytes/1048576) "USADO_GB",
	to_char(((sum(bytes/1048576))*100/(sum(maxbytes/1048576))),'999.99') ||'%' as "% USADO"
from dba_data_files 
group by rollup(tablespace_name)
union all
select 
	decode (grouping(tablespace_name),1, 'xTOTAL TEMPFILES',tablespace_name) "TABLESPACE",
    count(*) "QTDE",
	sum(maxbytes/1048576) "TOTAL_GB",
	sum(bytes/1048576) "USADO_GB",
	to_char(((sum(bytes/1048576))*100/(sum(maxbytes/1048576))),'999.99') ||'%' as "% USADO"
from dba_temp_files 
group by rollup(tablespace_name)
order by 1 ASC;

===========================================

--ou

SELECT
   DF.TABLESPACE_NAME                            "TABLESPACE",
   (DF.ACTUALSPACE - FS.FREESPACE)               "USED MB",
   FS.FREESPACE                                  "F_ACT MB",
   DF.ACTUALSPACE                                "ACT MB",
   ROUND(100 * (FS.FREESPACE / DF.ACTUALSPACE))  "F_ACT %",
   (DF.ACTUALSPACE - DD.TOTALSPACE)              "F_TOT MB",
   DD.TOTALSPACE								 "TOT MB"
   --ROUND(100 * ((DD.TOTALSPACE - DF.ACTUALSPACE) / DD.TOTALSPACE)) "F_TOT %"
FROM
   (SELECT TABLESPACE_NAME, ROUND(SUM(BYTES) / 1048576) ACTUALSPACE FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) DF,
   (SELECT TABLESPACE_NAME, ROUND(SUM(BYTES) / 1048576) FREESPACE FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) FS,
   (select TABLESPACE_NAME, ROUND(SUM(MAXBYTES) / 1048576) TOTALSPACE FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) DD
WHERE
   DF.TABLESPACE_NAME = FS.TABLESPACE_NAME(+)
   AND
   DF.TABLESPACE_NAME = DD.TABLESPACE_NAME(+)
   --AND DF.TABLESPACE_NAME = 'RUN_DATA'
   --AND FS.TABLESPACE_NAME = 'RUN_DATA'
   order by 1;
   
   
   

-- tamanho total do BD
SELECT      d.tablespace_name 											   "Name",            
            SUM(((a.bytes - DECODE(f.bytes, NULL, 0, f.bytes)) / 1048576)) "TOTAL_UTILIZADO (MB)"            
FROM        sys.dba_tablespaces d,
            sys.sm$ts_avail a, 
            sys.sm$ts_free f
WHERE       d.tablespace_name = a.tablespace_name 
AND         f.tablespace_name (+) = d.tablespace_name
GROUP BY    ROLLUP(d.tablespace_name);
   

--
-- Temporary Tablespace Sort Usage.
--
 
SET PAUSE ON
SET PAUSE 'Press Return to Continue'
SET PAGESIZE 60
SET LINESIZE 300
 
SELECT 
   A.tablespace_name tablespace, 
   D.mb_total,
   SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
   D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM 
   v$sort_segment A,
(
SELECT 
   B.name, 
   C.block_size, 
   SUM (C.bytes) / 1024 / 1024 mb_total
FROM 
   v$tablespace B, 
   v$tempfile C
WHERE 
   B.ts#= C.ts#
GROUP BY 
   B.name, 
   C.block_size
) D
WHERE 
   A.tablespace_name = D.name
GROUP by 
   A.tablespace_name, 
   D.mb_total
/