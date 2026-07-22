set feed off
alter session set nls_date_format='MM/DD/YYYY HH24:MI:SS';
set feed on
set lines 250 pages 999 verify off
col "TableSpace" for a30
col "File" for a45 word_wrapped
col creation_time for a20
select tablespace_name "TableSpace",file_name "File",round(f.BYTES/1024/1024,0) "SIZE (Mb)",file_id,
autoextensible,round(maxbytes/1024/1024,0) "MAXSIZE (Mb)", creation_time
from dba_data_files f,v$datafile d
where file_id=file#
and tablespace_name=upper('&1')
order by file_id
/
