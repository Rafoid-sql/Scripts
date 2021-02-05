--ver os blocos 
SELECT p1 "arquivo #", p2 "bloco #", p3 "classe #" 
FROM v$session_wait 
WHERE event = 'cadeias de buffer de cache';

--identificar os objetos
SELECT relative_fno, owner, segment_name, segment_type
FROM dba_extents
WHERE file_id = &file AND &block BETWEEN block_id AND block_id + blocks - 1;







