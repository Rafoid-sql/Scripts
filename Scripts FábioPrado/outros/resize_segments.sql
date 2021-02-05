-- Resize segments
select 
a.file_id, 
a.file_name,
SUM (ceil((nvl(hwm,1)*8192)/1024/1024/1024)) smallest, 
SUM (ceil(blocks*8192/1024/1024/1024)) currsize,
SUM (ceil(blocks*8192/1024/1024/1024) - ceil((nvl(hwm,1)*8192)/1024/1024/1024)) savings 
from dba_data_files a, 
(select file_id, max(block_id+blocks-1) hwm 
from dba_extents where owner='DBAASS'
AND segment_name = 'BANCO' 
group by file_id) b 
where a.file_id = b.file_id
ORDER BY 2;


SELECT A.BLOCKS, B.BLOCKS HWM, B.EMPTY_BLOCKS
FROM USER_SEGMENTS A, USER_TABLES BACKUPWHERE 
A.SEGMENT_NAME=B.TABLE_NAME 
AND B.TABLE_NAME='BANCO'

alter database datafile 102 resize 1029688k

select extent_id,blocks,block_id from dba_extents where segment_name='LOGO_BLOB' and owner='DBAASS';
