set lines 250 pages 999
col "TableSpace" for a40 word_wrapped
select d.tablespace_name "TableSpace",
round(a.bytes/1024/1024/1024) "Size(g)",
round(((a.bytes-DECODE(f.bytes,NULL,0,f.bytes))/1024/1024/1024),0) "Used(g)",
round(((a.bytes/1024/1024/1024)-((a.bytes-DECODE(f.bytes,NULL,0,f.bytes))/1024/1024/1024)),0) "Free(g)" ,
round(((a.bytes-DECODE(f.bytes,NULL,0,f.bytes))/1024/1024)/(a.bytes/1024/1024)*100,1) "Used Percent",
round(((a.bytes/1024/1024)-((a.bytes-DECODE(f.bytes,NULL,0,f.bytes))/1024/1024))/(a.bytes / 1024 / 1024)*100,1) "Percent Free"
from
sys.dba_tablespaces d,
sys.sm$ts_avail a,
sys.sm$ts_free f,
(select tablespace_name fs_ts_name,
             max(bytes) as max_bytes
      from sys.DBA_FREE_SPACE
      group by tablespace_name)
WHERE d.tablespace_name=a.tablespace_name
AND d.tablespace_name=fs_ts_name(+)
AND f.tablespace_name(+)=d.tablespace_name
--   and d.tablespace_name like 'USERS%'
order by "Percent Free";

