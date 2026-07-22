set lines 250 pages 999 verify off
SELECT thread#,to_date(to_char(FIRST_TIME,'MM/DD/YYYY HH24'),'MM/DD/YYYY HH24') DATE_HOUR, COUNT(*) FROM V$ARCHIVED_LOG
where dest_id=1
and FIRST_TIME > sysdate - &num_hours/24
GROUP BY thread#,to_date(to_char(FIRST_TIME,'MM/DD/YYYY HH24'),'MM/DD/YYYY HH24')
ORDER BY DATE_HOUR,thread#;

