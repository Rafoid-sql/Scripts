col name for a15
col state for a15
col gn for 99
col total_mb for 9999999999
col free_mb for 9999999999
col path for a30
col mount_status for a15
col header_status for a15
set lines 250 pages 999
select name,group_number as gn,state,total_mb,free_mb,round((free_mb/total_mb)*100,1) free_percent,100 - round((free_mb/total_mb)*100,1) used_percent,
path,mount_status,header_status from v$asm_disk
order by 2,1;
