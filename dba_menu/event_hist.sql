SET VERIFY OFF
COLUMN event FORMAT A30

SELECT event#,
       event,
       wait_time_milli,
       wait_count
FROM   v$event_histogram
WHERE  event LIKE '%&event_name%'
ORDER BY event, wait_time_milli;

COLUMN FORMAT DEFAULT
SET VERIFY ON
