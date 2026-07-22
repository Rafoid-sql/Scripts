set lines 250 pages 999 verify off
col begin_interval_time for a35
col inst for 99
col resource_name for a20
select   s.begin_interval_time, rl.instance_number inst , rl.resource_name, rl.current_utilization, rl.max_utilization
    from dba_hist_resource_limit rl, dba_hist_snapshot s
   where s.snap_id = rl.snap_id 
   and rl.resource_name = 'processes'
   and s.begin_interval_time > sysdate-&1/24
order by s.begin_interval_time, rl.instance_number;
