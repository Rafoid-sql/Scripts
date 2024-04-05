col TYPE for a20 Heading "Backup Type"
col completion_time Heading "Completion Time"
col MB for 99999999999  Heading "Size (MB)"
col BCPTIME for 99999999999 Heading "Backup Time (minutes)"

SELECT TO_CHAR (completion_time, 'YYYY-MON-DD') completion_time
       , TYPE
       , ROUND (SUM (bytes) / 1048576)          MB
       , ROUND (SUM (elapsed_seconds) / 60)     BCPTIME
    FROM (SELECT CASE
                    WHEN s.backup_type = 'L' THEN 'Archive Log'
--                    WHEN s.controlfile_included = 'YES' THEN 'Control File'
                 WHEN s.backup_type = 'D' THEN 'Full (Level ' || NVL (s.incremental_level, 0) || ')'
                    WHEN s.backup_type = 'I' THEN 'Incemental (Level ' || s.incremental_level || ')'
                    ELSE s.backup_type
                 END
                    TYPE
               , TRUNC (s.completion_time) completion_time
               , p.tag
               , p.bytes
               , s.elapsed_seconds
            FROM v$backup_piece p, v$backup_set s
           WHERE status = 'A' AND p.recid = s.recid
          UNION ALL
          SELECT 'Datafile Copy' TYPE, TRUNC (completion_time), tag, output_bytes, 0 elapsed_seconds FROM v$backup_copy_details)
GROUP BY tag, TO_CHAR (completion_time, 'YYYY-MON-DD'), TYPE
ORDER BY 1 ASC, 2, 3;