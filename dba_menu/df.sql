alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set lines 250 pages 999 verify off
col TableSpace for a25
col File for a50
col autoextensible for a4
select tablespace_name "TableSpace",file_name "File",round(f.BYTES/1024/1024,0) "SIZE (Mb)",file_id,AUTOEXTENSIBLE,round(MAXBYTES/1024/1024,0) "MAXSIZE (Mb)", creation_time
from dba_data_files f,v$datafile d
where file_id=file#
and tablespace_name=upper('&tbsp_name')
--where tablespace_name in (select distinct tablespace_name from dba_segments where segment_type='INDEX')
--and file_name like '/db01%'
order by tablespace_name,substr(file_name,instr(file_name, '/', -1)+1 );
--order by file_id desc;
--order by file_name;

