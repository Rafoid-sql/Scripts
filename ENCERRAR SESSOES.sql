
-- Listar sessões inativas
SELECT sid, serial#
FROM v$session
WHERE status = 'INACTIVE'
AND type <> 'BACKGROUND'
AND USERNAME='RONDON'
AND OSUSER <> 'SISTEMA'
AND last_call_et > 28800;


-- Encerrar sessões inativas
DECLARE
	CURSOR C1 IS
		SELECT sid, serial#
		FROM v$session
		WHERE status = 'INACTIVE'
		AND type <> 'BACKGROUND'
		AND USERNAME='RONDON'
		AND last_call_et > 28800;
BEGIN
	FOR reg_C1 IN C1
	LOOP
		EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION''' || reg_C1.sid || ',' || reg_C1.serial# || '''IMMEDIATE';
	END LOOP;
END;
/