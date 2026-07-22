set lines 250 pages 999 verify off
col event for a50
col i for 9
col session_id for 9999999
select * from (
SELECT inst_id i, session_id,decode(session_state,'WAITING',event,'ON CPU') event,count(*) ,round(count(*)/sum(count(*)) over () ,2)*100 pctload
FROM gv$active_session_history
WHERE
session_id=&1
AND sample_time > sysdate-&2/1440
AND session_type <> 'BACKGROUND'
GROUP by inst_id,session_id,decode(session_state,'WAITING',event,'ON CPU')
ORDER by count(*) desc
)
where rownum <= 5;
