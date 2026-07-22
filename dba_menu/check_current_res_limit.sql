set lines 250 pages 999
col resource_name for a25
col initial_allocation for a20
col limit_value for a20
select resource_name,current_utilization,max_utilization,initial_allocation,limit_value from v$resource_limit order by 1;
