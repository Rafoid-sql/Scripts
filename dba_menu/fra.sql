set lines 250 pages 999
col name for a30
select name,
round(space_limit /(1024*1024*1024)) space_limit_in_gb,
round(space_used /(1024*1024*1024)) space_used_in_gb,
round(space_reclaimable/(1024*1024*1024)) space_reclaim_in_gb,
round(((space_limit-space_used)+space_reclaimable)/(1024*1024*1024)) space_aval_in_gb,
round(((space_used-space_reclaimable)/space_limit)*100,2) percent_usage
from v$recovery_file_dest
where name is not null;

