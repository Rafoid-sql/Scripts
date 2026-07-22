set lines 250 pages 999 verify off
col event for a50

select * from (
SELECT sql_id ,decode(session_state,'WAITING',event,'ON CPU') event,count(*) ,round(count(*)/sum(count(*)) over () ,2)*100 pctload
FROM gv$active_session_history
WHERE
sample_time > sysdate-&1/1440
AND session_type <> 'BACKGROUND'
GROUP by sql_id,decode(session_state,'WAITING',event,'ON CPU')
ORDER by count(*) desc
)
where rownum <= 10
/
