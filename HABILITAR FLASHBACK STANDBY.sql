--HABILITAR FLASHBACK EM UM STANDBY:

--https://grepora.com/2016/10/05/ora-01153-an-incompatible-media-recovery-is-active/
--http://karandba.blogspot.com/2015/11/how-to-enable-flashback-in-standby.html

/*
===============================================================
SQL>  alter database flashback on;
 alter database flashback on
ERROR at line 1:
ORA-01153: an incompatible media recovery is active
===============================================================
*/

-- Verificar se o processo "MRPx" está sendo executado:
SELECT PROCESS,CLIENT_PROCESS,THREAD#,SEQUENCE#,BLOCK# FROM V$MANAGED_STANDBY WHERE PROCESS = 'MRP0' OR CLIENT_PROCESS='LGWR';

-- Pausar a sincronização do standby:
RECOVER MANAGED STANDBY DATABASE CANCEL;

-- Habilitar o flashback:
ALTER DATABASE FLASHBACK ON;

-- Reiniciar a sincronização do standby:
RECOVER MANAGED STANDBY DATABASE DISCONNECT;

/*
############Dataguard##########
*/

--Baixar:
--Produção!
dgmgrl
connect sys/te
disable configuration;

--Dataguard!
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL; 


--Verificar tempo de atualização do standby no dataguard
SELECT ROUND(TRUNC((SELECT SYSDATE - MAX(TIMESTAMP) FROM V$RECOVERY_PROGRESS) * 24 * 60 * 60)) REPLICATION_LAG FROM DUAL; 


--Voltar:
--Produção!
dgmgrl
connect sys/te
enable configuration;

--Dataguard!

--Verificar tempo de atualização do standby no dataguard
SELECT ROUND(TRUNC((SELECT SYSDATE - MAX(TIMESTAMP) FROM V$RECOVERY_PROGRESS) * 24 * 60 * 60)) REPLICATION_LAG FROM DUAL; 

--Caso não funcionar reativar replicação dos archives manualmente 
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;