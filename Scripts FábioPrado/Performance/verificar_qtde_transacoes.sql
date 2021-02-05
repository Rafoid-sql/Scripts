-- qtde de transacoes por segundo (dos ultimos 60 segundos)
SELECT      'Txns Per Sec', a.epx / b.ept
FROM        (   SELECT  value epx
                FROM    v$sysmetric
                WHERE   group_id = 2 -- 60 sec interval
                AND     metric_name = 'Executions Per Sec' ) a,
            (   SELECT  value ept
                FROM    v$sysmetric
                WHERE   group_id = 2 -- 60 sec interval
AND         metric_name = 'Executions Per Txn' ) b


col name for a55
select NAME, SEQUENCE#, APPLIED, to_char(FIRST_TIME,'dd/mm/yyyy hh24:mi:ss'), to_char(NEXT_TIME, 'dd/mm/yyyy hh24:mi:ss'), to_char(COMPLETION_TIME, 'dd/mm/yyyy hh24:mi:ss'), round((blocks*BLOCK_SIZE)/1024/1024,2) size_mb from v$archived_log where COMPLETION_TIME > trunc(sysdate-5) and name is not null order by FIRST_TIME;