set lines 250 pages 999
col tablespace_name for a40
col Space_in_MB for 99999999
select ts_name tablespace_name,round(sum(space)*8192/1048576) Space_in_MB from dba_recyclebin
where ts_name is not null group by ts_name
order by 2 desc;

col owner for a30
col object_name for a30
col original_name for a30
col ts_name for a30
select owner,object_name,original_name,droptime,ts_name,operation,type 
from dba_recyclebin where ts_name is not null order by droptime;
