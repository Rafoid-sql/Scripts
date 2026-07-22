col name for a15
col state for a20
col TOTAL_MB for 9999999999
col FREE_MB for 9999999999
set lines 250 pages 999
select NAME,STATE,TOTAL_MB,(TOTAL_MB-FREE_MB)USED_MB,FREE_MB,round((FREE_MB/TOTAL_MB*100),2) PERCENT_FREE,ALLOCATION_UNIT_SIZE ALLOC_UNIT_SIZE
from v$asm_diskgroup_stat
where total_mb <> 0
order by PERCENT_FREE asc;
