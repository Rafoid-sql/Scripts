SELECT RESOURCE_NAME, CURRENT_UTILIZATION, MAX_UTILIZATION FROM V$RESOURCE_LIMIT WHERE RESOURCE_NAME IN ('PROCESSES','SESSIONS');

SELECT RESOURCE_NAME, CURRENT_UTILIZATION, MAX_UTILIZATION FROM V$RESOURCE_LIMIT WHERE RESOURCE_NAME='PROCESSES';