set lines 250 pages 999 verify off
select to_char(FIRST_TIME,'MM/DD/YYYY HH24') DAY_HOUR, COUNT(*) cnt ,sum(round((blocks*block_size)/1048576)) total_size_MB
FROM V$ARCHIVED_LOG
where dest_id=1 
and FIRST_TIME > trunc(sysdate)-&1
GROUP BY to_char(FIRST_TIME,'MM/DD/YYYY HH24')
order by DAY_HOUR DESC;
