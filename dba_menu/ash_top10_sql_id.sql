set verify off
select * from (
SELECT sql_id ,count(*) ,round(count(*)/sum(count(*)) over () ,2)*100 pctload
FROM gv$active_session_history
WHERE
sample_time > sysdate - &1/1440
AND session_type <> 'BACKGROUND'
GROUP by sql_id
ORDER by count(*) desc
)
where rownum <= 10;
