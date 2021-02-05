
 select substr(file_name,1,4) as "FileSystem", sum(bytes)/1024/1024 as "Tamanho(MB)" 
 from dba_data_files group by rollup(substr(file_name,1,4)) order by substr(file_name,1,4);
 
 
 select tablespace_name, sum(bytes)/1024/1024 as "TAMANHO(MB)" from dba_data_files group by tablespace_name order by sum(bytes);

 
 select tablespace_name, sum(bytes)/1024/1024 as "TAMANHO(MB)" from dba_free_space group by tablespace_name order by sum(bytes);


select 'alter database datafile ''' || file_name || ''' resize ' ||
      ceil( (nvl(hwm,1)*8192*1.2)/1024/1024 )  || 'm;' cmd
from dba_data_files a,
    ( select file_id, max(block_id+blocks-1) hwm
       from dba_extents
       group by file_id ) b
where a.file_id = b.file_id(+)
 and ceil( (nvl(hwm,1)*8192*1.2)/1024/1024 ) < ceil( blocks*8192/1024/1024)
 and ceil( (nvl(hwm,1)*8192*1.2)/1024/1024 ) > 100