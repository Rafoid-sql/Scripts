-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
--COMPATIBILIDADE

--ASM Compat Parameter:
SELECT NAME AS DISKGROUP, SUBSTR(COMPATIBILITY,1,12) AS ASM_COMPAT, SUBSTR(DATABASE_COMPATIBILITY,1,12) AS DB_COMPAT FROM V$ASM_DISKGROUP;

--ASM Attributes:
COL VALUE FOR A20
COL NAME FOR A20
SELECT GROUP_NUMBER, NAME, VALUE FROM V$ASM_ATTRIBUTE ORDER BY GROUP_NUMBER, NAME;
=========================================================================================================================================
-- Check Lun size for ASM Disk size
SELECT D.PATH, D.GROUP_NUMBER, G.NAME, D.OS_MB/1024 GB FROM V$ASM_DISK D LEFT OUTER JOIN V$ASM_DISKGROUP G ON (D.GROUP_NUMBER = G.GROUP_NUMBER) ORDER BY G.GROUP_NUMBER, D.OS_MB;
=========================================================================================================================================
-- Check Asm Disk Group Size I
SET LINES 280
SET PAGESIZE 1000
BREAK ON REPORT ON DISK_GROUP_NAME SKIP 1
COMPUTE SUM LABEL "GRAND TOTAL: " OF TOTAL_MB USED_MB ON REPORT
SELECT NAME GROUP_NAME, ROUND(TOTAL_MB) TOTAL_MB, ROUND((TOTAL_MB - FREE_MB)) USED_MB, ROUND(FREE_MB) FREE_MB, ROUND((1-(FREE_MB/TOTAL_MB))*100,2) USED, (100-ROUND((1-(FREE_MB/TOTAL_MB))*100,2)) FREE 
FROM V$ASM_DISKGROUP 
ORDER BY NAME;
=========================================================================================================================================
-- Check Asm Disk Group Size II
SET LINES 280
SET PAGESIZE 1000
BREAK ON REPORT ON DISK_GROUP_NAME SKIP 1
COMPUTE SUM LABEL "GRAND TOTAL: " OF TOTAL_MB USED_MB ON REPORT
SELECT NAME GROUP_NAME, ROUND(TOTAL_MB) TOTAL_MB, ROUND((TOTAL_MB - FREE_MB)) USED_MB, ROUND(FREE_MB) FREE_MB, 
CASE WHEN TOTAL_MB = 0 THEN 0 ELSE ROUND((1 - (FREE_MB / TOTAL_MB)) * 100, 2) END USED, 
CASE WHEN TOTAL_MB = 0 THEN 100 ELSE 100 - ROUND((1 - (FREE_MB / TOTAL_MB)) * 100, 2) END FREE
FROM V$ASM_DISKGROUP 
ORDER BY NAME;
=========================================================================================================================================
-- ASM SPECIFIG DISKGROUP:
SELECT NAME GROUP_NAME, ROUND(TOTAL_MB) TOTAL_MB, ROUND(FREE_MB) FREE_MB, ROUND((1-(FREE_MB/TOTAL_MB))*100,2) USED, (100-ROUND((1-(FREE_MB/TOTAL_MB))*100,2)) FREE 
FROM V$ASM_DISKGROUP 
WHERE NAME IN ('DATA','FRA');

ALTER TABLESPACE  AUDIT_DATA ADD DATAFILE '+DATA' SIZE 2048M AUTOEXTEND ON MAXSIZE 30G;
=========================================================================================================================================
-- CHECK ASM DISKS STATUS:
COL GROUP FOR A5
COL CONNECTION FOR A10
COL TYPE FOR A10
COL STATUS FOR A10
COL NAME FOR A15
COL PATH FOR A30
COL STATE FOR A10
SELECT TO_CHAR(DG.GROUP_NUMBER) "GROUP", DG.STATE "CONNECTION", DG.TYPE, DK.HEADER_STATUS "STATUS", DK.NAME, DK.PATH, DK.STATE
FROM V$ASM_DISKGROUP DG, V$ASM_DISK DK
WHERE DG.GROUP_NUMBER = DK.GROUP_NUMBER
ORDER BY DK.NAME;
=========================================================================================================================================
--3) Flash recovery size..
COL NAME FOR A32
COL SIZE_M FOR 999,999,999
COL RECLAIMABLE_M FOR 999,999,999
COL USED_M FOR 999,999,999
COL PCT_USED FOR 999
SELECT NAME, CEIL( SPACE_LIMIT / 1024 / 1024) SIZE_M, CEIL( SPACE_USED  / 1024 / 1024) USED_M, CEIL( SPACE_RECLAIMABLE  / 1024 / 1024) RECLAIMABLE_M, DECODE( NVL( SPACE_USED, 0),0, 0, CEIL ( ( ( SPACE_USED - SPACE_RECLAIMABLE ) / SPACE_LIMIT) * 100) ) PCT_USED FROM V$RECOVERY_FILE_DEST ORDER BY NAME;
=========================================================================================================================================
--4) Asm Disk Group Size..
SET LINESIZE  145
SET PAGESIZE  9999
SET VERIFY    OFF
COLUMN GROUP_NAME             FORMAT A20           HEAD 'DISK GROUP|NAME'
COLUMN SECTOR_SIZE            FORMAT 99,999        HEAD 'SECTOR|SIZE'
COLUMN BLOCK_SIZE             FORMAT 99,999        HEAD 'BLOCK|SIZE'
COLUMN ALLOCATION_UNIT_SIZE   FORMAT 999,999,999   HEAD 'ALLOCATION|UNIT SIZE'
COLUMN STATE                  FORMAT A11           HEAD 'STATE'
COLUMN TYPE                   FORMAT A6            HEAD 'TYPE'
COLUMN TOTAL_MB               FORMAT 999,999,999   HEAD 'TOTAL SIZE (MB)'
COLUMN USED_MB                FORMAT 999,999,999   HEAD 'USED SIZE (MB)'
COLUMN PCT_USED               FORMAT 999.99        HEAD 'PCT. USED'
BREAK ON REPORT ON DISK_GROUP_NAME SKIP 1
COMPUTE SUM LABEL "GRAND TOTAL: " OF TOTAL_MB USED_MB ON REPORT
SELECT NAME GROUP_NAME , SECTOR_SIZE, BLOCK_SIZE, ALLOCATION_UNIT_SIZE, STATE, TYPE, TOTAL_MB, (TOTAL_MB - FREE_MB) USED_MB, ROUND((1- (FREE_MB / TOTAL_MB))*100, 2) PCT_USED FROM V$ASM_DISKGROUP ORDER BY NAME;
=========================================================================================================================================
--5)Oracle Database : Space used in the flash recovery area.
SET LINES 900 PAGES 900
COL NAME FOR A15
COL SPACE_LIMIT FOR A15
COL SPACE_USED FOR A15
SELECT NAME,SPACE_LIMIT/1024/1024,SPACE_USED/1024/1024 FROM V$RECOVERY_FILE_DEST;

SELECT NAME, FLOOR(SPACE_LIMIT/1024/1024) "SIZE_MB", CEIL(SPACE_USED/1024/1024) "USED_MB", FLOOR(SPACE_LIMIT/1024/1024) - CEIL(SPACE_USED/1024/1024) "AVAILABLE_MB", ROUND(CEIL(SPACE_USED/1024/1024) / FLOOR(SPACE_LIMIT/1024/1024) * 100)  || '%' "PERCENT USED" FROM V$RECOVERY_FILE_DEST ORDER BY 1;
=========================================================================================================================================
--REMOVER DISCOS DO DISKGROUP

--Remover o disco:
ALTER DISKGROUP DATA DROP DISK DATA_0002, DATA_0003;

--Aguardar o Rebal:
SELECT GROUP_NUMBER, OPERATION, STATE, EST_MINUTES FROM V$ASM_OPERATION;
=========================================================================================================================================
--ADICIONAR DISCOS AO DISKGROUP

--lista todos os discos
blkid | grep asm 

--Para verificar se um ambiente é +ASM realizamos o seguinte comando.
[grid@imne12:+ASM2 ~]$ olsnodes -s
imne10  Active
imne12  Active

--Com o comando abaixo conseguimos listar os discos disponivel que o ORACLE enxerga.
$ /usr/sbin/oracleasm listdisks

--O comando abaixo realiza um scandisks para buscar os disco ativos no nó. Fazendo um "Scanning the system for Oracle ASMLib disks".
# /etc/init.d/oracleasm scandisks 
=========================================================================================================================================
--LISTA DISKGROUPS DO ASM:
SELECT GROUP_NUMBER, NAME FROM V$ASM_DISKGROUP;
=========================================================================================================================================
--LISTA DISCOS DOS DISKGROUPS:
SET LINE 300
SET PAGESIZE 100
COL GN FOR 99
COL NAME FOR A20
COL PATH FOR A40
COL FAILGROUP FOR A20
COL LABEL FOR A20
SELECT GROUP_NUMBER AS GN, NAME, FAILGROUP, MOUNT_STATUS, HEADER_STATUS, MODE_STATUS, LABEL, PATH, TOTAL_MB, FREE_MB, CREATE_DATE, MOUNT_DATE FROM V$ASM_DISK ORDER BY LABEL, PATH;
/*
NAME                           MOUNT_S HEADER_STATU MODE_ST LABEL                           PATH                             TOTAL_MB    FREE_MB
DGDATA01                       CACHED  MEMBER       ONLINE  DGDATA01                        ORCL:DGDATA01                       51210        621
DGDATA16                       CLOSED  FORMER       ONLINE  DGDATA16                        ORCL:DGDATA16                           0          0
DGDATA17                       CLOSED  PROVISIONED  ONLINE  DGDATA17                        ORCL:DGDATA17                           0          0
DGRECO01                       CACHED  MEMBER       ONLINE  DGRECO01                        ORCL:DGRECO01                       51210      50532
*/
=========================================================================================================================================
--ESPAÇO DISPONÍVEL NOS DISKGROUPS:
SELECT  A.*, (A.TOTAL_MB - A.FREE_MB) AS USED_MB, ROUND(((A.TOTAL_MB - A.FREE_MB) / TOTAL_MB) * 100, 2) AS PERC_USED
FROM (SELECT GROUP_NUMBER, NAME,'TYPE, ROUND((TOTAL_MB - REQUIRED_MIRROR_FREE_MB) / DECODE(TYPE, 'EXTERN', 1, 'NORMAL', 2, 'HIGH', 3, 1), 2) AS TOTAL_MB, ((FREE_MB - REQUIRED_MIRROR_FREE_MB) '/'' DECODE(TYPE, 'EXTERN', 1, 'NORMAL', 2, 'HIGH', 3, 1)) AS FREE_MB FROM V$ASM_DISKGROUP) A WHERE A.TOTAL_MB > 0;
=========================================================================================================================================
--ADICIONANDO DOIS DISCO NO DISKGROUP +DGDATA
ALTER DISKGROUP MY_DISKGROUP ADD DISK '/DEVICES/RHDISK1' NAME RHDISK1; 
=========================================================================================================================================
--verificar o status do rebalance:
SELECT GROUP_NUMBER, OPERATION, STATE, EST_MINUTES FROM V$ASM_OPERATION;
=========================================================================================================================================
--VERIFICAR SE OS DISCOS ESTAO BALANCEADOS NO ASM
SELECT DG.NAME, DG.ALLOCATION_UNIT_SIZE/1024/1024 "AU(MB)", MIN(D.FREE_MB) MIN, MAX(D.FREE_MB) MAX, ROUND(AVG(D.FREE_MB),0) AVG FROM V$ASM_DISK D, V$ASM_DISKGROUP DG WHERE D.GROUP_NUMBER = DG.GROUP_NUMBER GROUP BY DG.NAME, DG.ALLOCATION_UNIT_SIZE/1024/1024;
=========================================================================================================================================
--ver os discos
COLUMN PATH FORMAT A20
SET LINES 132
SET PAGES 50
SELECT PATH, GROUP_NUMBER GROUP_#, DISK_NUMBER DISK_#, MOUNT_STATUS,NAME HEADER_STATUS, STATE, TOTAL_MB, FREE_MB FROM V$ASM_DISK WHERE  GROUP_NUMBER = 1 ORDER BY GROUP_NUMBER;
SELECT NAME,STATE,GROUP_NUMBER FROM V$ASM_DISKGROUP;
SELECT TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'),TO_CHAR(SYSDATE+EST_MINUTES/1440,'DD/MM/YYYY HH24:MI:SS'),T.* FROM V$ASM_OPERATION T;
=========================================================================================================================================
--checar sequencias:
set lines 400
set pages 2000
alter session set nls_date_format = 'DD-MON-YYYY HH24:mi:SS';
SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference", sysdate
FROM
(SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,
(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL
WHERE
ARCH.THREAD# = APPL.THREAD#
ORDER BY 1;