set lines 250 pages 999 verify off
col owner for a30
col segment_name for a30
select owner,segment_name
from dba_extents
where file_id = &1
and &2 between block_id and block_id + blocks - 1
and rownum = 1;

undefine 1
undefine 2
