SELECT m.tablespace_name,
    round(max(m.used_percent),1) PERCM,
    round(max(m.used_space*t.block_size)*100/(sum(d.bytes)*count(distinct d.file_id)/count(d.file_id)),1) PERC,
    round(max(m.tablespace_size*t.block_size/1024/1024),1) TOTALM,
    round((sum(d.bytes)*count(distinct d.file_id))/count(d.file_id)/1024/1024,1) TOTAL,
    round(max(m.used_space*t.block_size/1024/1024),1) USED,
    round(max((m.tablespace_size-m.used_space)*t.block_size/1024/1024),1) FREEM,
    round(((sum(d.bytes)*count(distinct d.file_id))/count(d.file_id)-max(m.used_space*t.block_size))/1024/1024,1) FREE,    
    count(distinct d.file_id) DBF_NO,
    max(to_number(tt.warning_value)) WARN,
    max(to_number(tt.critical_value)) CRIT,
    max(case when m.used_percent>tt.warning_value OR m.used_percent>tt.critical_value then 'NO!' else 'OK' end) "OK?"
FROM  dba_tablespace_usage_metrics m, dba_tablespaces t, dba_data_files d, dba_thresholds tt
WHERE m.tablespace_name=t.tablespace_name
AND d.tablespace_name=t.tablespace_name
and tt.metrics_name='Tablespace Space Usage'
and tt.object_name is null
GROUP BY m.tablespace_name
order by 2 desc;