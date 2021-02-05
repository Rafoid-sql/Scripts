SELECT d.undo_size/(1024*1024) "ACTUAL UNDO SIZE [MByte]", SUBSTR(e.value,1,25) "UNDO RETENTION [Sec]", 
(TO_NUMBER(e.value) * TO_NUMBER(f.value) * g.undo_block_per_sec) / (1024*1024) "NEEDED UNDO SIZE [MByte]"
FROM (SELECT SUM(a.bytes) undo_size FROM v$datafile a
inner join v$tablespace b on a.ts# = b.ts#
inner join dba_tablespaces c on b.name = c.tablespace_name
WHERE c.contents = 'UNDO' AND c.status = 'ONLINE') d, v$parameter e, v$parameter f,        
(SELECT   MAX(undoblks/((end_time-begin_time)*3600*24)) undo_block_per_sec FROM v$undostat) g
WHERE e.name = 'undo_retention' AND f.name = 'db_block_size';