--CASO O AMBIENTE SEJA RAC, DEIXAR UM INTERVALO ENTRE AS EXECUÇÕES DOS NODES PARA EVITAR CONCORRÊNCIA NOS OBJETOS.

--#########################################################################
--### CRIAR
--#########################################################################

--Criar tablespace PERFDATA
	CREATE TABLESPACE PERFDATA DATAFILE '/u02/oradata/dbprod/perfdata_01.dbf' SIZE 256M REUSE AUTOEXTEND ON NEXT 128M MAXSIZE 4G;

--Criar usuário PERFSTAT
	@?/rdbms/admin/spcreate.sql
	
--#########################################################################
--### COLETAR
--#########################################################################

--Criar coleta automática
	@?/rdbms/admin/spauto.sql

--Criar coleta via Scheduler (RAC)
	BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
	JOB_NAME => 'SNAP_INST_2',
	JOB_TYPE => 'STORED_PROCEDURE',
	JOB_ACTION => 'STATSPACK.SNAP',
	REPEAT_INTERVAL => 'FREQ=HOURLY; BYMINUTE=5',
	AUTO_DROP => FALSE,
	ENABLED => TRUE,
	COMMENTS => 'STATSPACK AUTOMATED SNAP INSTANCE 2');
	END;
	/

	BEGIN
	DBMS_SCHEDULER.SET_ATTRIBUTE('SNAP_INST_2','INSTANCE_ID',2);
	END;
	/

--Gerar coleta manual
	EXEC STATSPACK.snap

--#########################################################################
--### EXPURGAR
--#########################################################################

--Criar procedure de expurgo (Single, RAC):
	CREATE OR REPLACE PROCEDURE STATSPACKPURGE IS
	VAR_LO_SNAP NUMBER;
	VAR_HI_SNAP NUMBER;
	VAR_DB_ID NUMBER;
	VAR_INSTANCE_NO NUMBER;
	NOOFSNAPSHOT NUMBER;
	N_COUNT NUMBER ;
	BEGIN
	FOR INST_NO IN (SELECT DISTINCT INSTANCE_NUMBER FROM STATS$SNAPSHOT)
	LOOP
	N_COUNT := 0;
	SELECT COUNT(*) INTO N_COUNT FROM STATS$SNAPSHOT WHERE SNAP_TIME < SYSDATE-2 AND INSTANCE_NUMBER = INST_NO.INSTANCE_NUMBER; 
	IF N_COUNT > 0 THEN
	SELECT MIN(S.SNAP_ID) , MAX(S.SNAP_ID),MAX(DI.DBID) INTO VAR_LO_SNAP, VAR_HI_SNAP,VAR_DB_ID
	FROM STATS$SNAPSHOT S, STATS$DATABASE_INSTANCE DI
	WHERE S.DBID = DI.DBID AND S.INSTANCE_NUMBER = INST_NO.INSTANCE_NUMBER AND S.INSTANCE_NUMBER = DI.INSTANCE_NUMBER AND DI.STARTUP_TIME = S.STARTUP_TIME AND S.SNAP_TIME < SYSDATE-2; 
	NOOFSNAPSHOT := STATSPACK.PURGE( I_BEGIN_SNAP => VAR_LO_SNAP, I_END_SNAP => VAR_HI_SNAP, I_SNAP_RANGE => TRUE, I_EXTENDED_PURGE => FALSE, I_DBID => VAR_DB_ID, I_INSTANCE_NUMBER => INST_NO.INSTANCE_NUMBER);
	DBMS_OUTPUT.PUT_LINE('INSTANCE: '||INST_NO.INSTANCE_NUMBER||' / SNAPSHOT DELETED: '||TO_CHAR(NOOFSNAPSHOT));
	END IF;
	END LOOP;
	END;
	/
	
--Criar job de expurgo
--dbms_jobs
	DECLARE
	  MY_JOB NUMBER;
	BEGIN
	  DBMS_JOB.SUBMIT(JOB => MY_JOB,
		WHAT => 'STATSPACKPURGE;',
		NEXT_DATE => TRUNC(SYSDATE)+7,
		INTERVAL => 'TRUNC(SYSDATE)+7');
	END;
	/

--dbms_scheduler:
	BEGIN
	SYS.DBMS_SCHEDULER.CREATE_JOB( 
	JOB_NAME => 'PURGE_SNAPSHOTS',
	JOB_TYPE => 'STORED_PROCEDURE',
	JOB_ACTION => 'STATSPACKPURGE',
	REPEAT_INTERVAL => 'FREQ=DAILY;BYHOUR=1;BYMINUTE=0',
	START_DATE => SYSTIMESTAMP,
	JOB_CLASS => 'DEFAULT_JOB_CLASS',
	COMMENTS => 'FAZ O PURGE DE SNAPSHOTS DO STATSPACK',
	AUTO_DROP => FALSE,
	ENABLED => TRUE);
	END;
	/

--Changing job repeat_interval / schedule / frequency
	BEGIN
	DBMS_SCHEDULER.SET_ATTRIBUTE('PURGE_SNAPSHOTS','REPEAT_INTERVAL','FREQ=DAILY;BYHOUR=6;BYMINUTE=0');
	END;

--Expurgo manual
	@?/rdbms/admin/sppurge.sql
OU
	EXEC STATSPACK.PURGE( I_BEGIN_SNAP => 1, I_END_SNAP => 5182, I_SNAP_RANGE => TRUE, I_EXTENDED_PURGE => FALSE, I_DBID => 1838110350, I_INSTANCE_NUMBER => 1);

--#########################################################################
--### LISTAR
--#########################################################################

--Listar snapshots
	SELECT NAME,SNAP_ID,INSTANCE_NUMBER,TO_CHAR(SNAP_TIME,'DD-MON-YYYY:HH24:MI:SS') "DATE/TIME" FROM STATS$SNAPSHOT,V$DATABASE;

-- Listar jobs criados	
	SET LINES 300
	COL OWNER FOR A10
	COL JOB_NAME FOR A20
	COL INSTANCE_ID FOR 99
	COL JOB_ACTION FOR A20
	COL NEXT_RUN_DATE FOR A40
	SELECT OWNER,JOB_NAME,INSTANCE_ID,JOB_ACTION,NEXT_RUN_DATE FROM DBA_SCHEDULER_JOBS WHERE JOB_NAME LIKE 'SNAP%';

--Select snapshots
	ALTER SESSION SET NLS_DATE_FORMAT='DD/MM/YYYY HH24:MI:SS';
	COL HOST_NAME FORMAT A30
	SELECT DISTINCT SNAP.SNAP_ID, SNAP.SNAP_TIME, SNAP.DBID, DI.DB_NAME, SNAP.INSTANCE_NUMBER, DI.INSTANCE_NAME, DI.HOST_NAME
	FROM STATS$SNAPSHOT SNAP, STATS$DATABASE_INSTANCE DI
	WHERE DI.DBID = SNAP.DBID
	AND SNAP.INSTANCE_NUMBER = DI.INSTANCE_NUMBER
	AND SNAP_TIME > SYSDATE-7
	--AND DI.INSTANCE_NUMBER=1
	ORDER BY 2;

--#########################################################################
--### REPORTAR
--#########################################################################

--Criar report statspack
	@?/rdbms/admin/spreport.sql

--#########################################################################
--### REMOVER
--#########################################################################

--Remover statspack
	@?/rdbms/admin/spdrop.sql
	