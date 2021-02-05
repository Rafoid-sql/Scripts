-- consultar deadlocks no alert xml (11g em diante) por mes:
SELECT      TO_CHAR(ORIGINATING_TIMESTAMP,'yyyy/mm') DATA, 
            count(1)
FROM        X$DBGALERTEXT 
WHERE       MESSAGE_TEXT LIKE '%Deadlock%'
GROUP BY    TO_CHAR(ORIGINATING_TIMESTAMP,'yyyy/mm')
ORDER BY    1 DESC;


Select a1.sid, ' esta bloqueando ', a2.sid
From v$lock a1, v$lock a2
Where a1.block = 1
And a2.request > 0
And a1.id1=a2.id1
And a1.id2=a2.id2;