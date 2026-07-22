prompt checking database status...
set lines 250 pages 999
select name,db_unique_name,open_mode,flashback_on,database_role,switchover_status from v$database;

prompt Current log sequence...
select thread#, sequence# from v$log where status='CURRENT';

prompt archive_dest_status...
set lines 250 pages 999
col dest_name for a20
col destination for a25
col error for a50
select inst_id,dest_id,dest_name,status,type,database_mode,recovery_mode,destination,error
from gv$archive_dest_status
where destination is not null
order by dest_id,inst_id;
