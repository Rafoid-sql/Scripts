-- consultar objetos bloqueados por usuario
SELECT    LO.SESSION_ID, LO.PROCESS, LO.ORACLE_USERNAME, O.OWNER, O.OBJECT_NAME
FROM      V$LOCKED_OBJECT LO
JOIN      DBA_OBJECTS O
  ON      O.OBJECT_ID = LO.OBJECT_ID;

-- consultar locks que estao bloqueando outras sessoes
SELECT  L.SESSION_ID, L.LOCK_TYPE, L.MODE_HELD, L.LOCK_ID1, L.LOCK_ID2, L.BLOCKING_OTHERS
FROM    DBA_LOCKS L
WHERE   L.BLOCKING_OTHERS <> 'Not Blocking';

-- consultar sessoes bloqueadoras
select * from dba_blockers;

-- consultar sessoes bloqueadas
select * from dba_waiters;


