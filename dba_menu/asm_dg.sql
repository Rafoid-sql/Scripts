set lines 250 pages 999
col name for a20
select name,state,total_mb,(total_mb-free_mb)used_mb,free_mb,round((free_mb/total_mb*100),2) percent_free,allocation_unit_size alloc_unit_size
from v$asm_diskgroup_stat
where total_mb <> 0
order by PERCENT_FREE asc;
