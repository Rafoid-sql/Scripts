-- RECOVER STANDBY USANDO RMAN BACKUP INCREMENTAL

--1 - (STB) Criar controlfile da base STB / Listar diret�rio dos datafiles que ser� necess�rio renomear:
ALTER DATABASE BACKUP CONTROLFILE TO TRACE;

--OBS: Caso necess�rio, renomear os datafiles antes de continuar

--2 - (STB) Abrir banco de standby em modo READ ONLY:
ALTER DATABASE OPEN READ ONLY;

--3 - (STB) Verificar �ltimo SCN do standby:
SELECT TO_CHAR(Current_scn, '9999999999999999') "Current SCN" FROM V$DATABASE;
/*
Current SCN
-----------------
      45649944579
*/

--4 - (PRD) Executar comando de backup na produ��o:
RMAN> 
run{
allocate channel d1 type disk FORMAT '/u01/app/oracle/fast_recovery_area/ForStandby_%U' maxpiecesize 5120M;
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL FROM SCN 36220651554 database format '/u01/app/oracle/fast_recovery_area/ForStandby_%U' tag 'FORSTANDBY';
BACKUP CURRENT CONTROLFILE FOR STANDBY FORMAT '/u01/app/oracle/fast_recovery_area/ForStandbyCTRL.bck';
}

--5 - (PRD) Enviar os arquivos gerados pelo rman para o standby:
$ "scp /u02/fast_recovery_area/* 1.0.2.146:/orabackup/restore/"

--6 - (STB) Catalogar os backups no standby:
RMAN> 
CATALOG START WITH '/u01/app/oracle/standby/opositivosa/';

--7 - (STB) Efetuar o restore do standby (necess�rio banco estar em modo mount):
RMAN> 
SHUTDOWN IMMEDIATE
STARTUP MOUNT
RECOVER DATABASE NOREDO;

--8 - (STB) Efetuar o recover do control file:
RMAN> 
SHUTDOWN;
STARTUP NOMOUNT;
RESTORE STANDBY CONTROLFILE FROM '/u01/app/oracle/standby/opositivosa/ForStandbyCTRL.bck';

--9 - (STB) Efetuar shutdown do standby:
RMAN> 
SHUTDOWN;
STARTUP MOUNT;

--10 - (PRD) Gerar um ultimo archive no produ��o:
ALTER SYSTEM SWITCH LOGFILE;

--11 - (PRD) Copiar os ultimos archives para o standby:
$ "scp /orabackup/restore_stb/* 1.0.2.146:/orabackup/restore/"

--12 - (STB) Conectar no standby:
ALTER DATABASE RECOVER AUTOMATIC STANDBY DATABASE;

--13 - (STB) Abrir standby no modo read-only:
ALTER DATABASE OPEN READ ONLY;
