SELECT a.group#, a.member, b.bytes
FROM v$logfile a, v$log b 
WHERE a.group# = b.group#;


select group#, status from v$log;

alter system switch logfile;
ALTER DATABASE DROP LOGFILE GROUP 3;


alter database add logfile group 9 '+DGDATA/dbass/redo09a.log' size 500M reuse;

ALTER DATABASE ADD LOGFILE MEMBER '+DGRECO/dbass/redo09b.log' TO GROUP 9 size 500M;
alter database add logfile group 9 '+DGRECO/dbass/redo09b.log' size 500M reuse;
alter database add logfile group 4 '/u01/oradata/orahom/redo04.log' size 500M;
alter database add standby logfile group 4 '/oraprd/oradata/redo_st04.log' size 100M;
alter database add standby logfile group 5 '/oraprd/oradata/redo_st05.log' size 100M;
alter database add logfile group 6 '/u01/oradata/orahom/redo06.log' size 300M;
alter database add logfile group 7 '/u01/oradata/orahom/redo07.log' size 300M;
alter database add logfile group 8 '/u01/oradata/orahom/redo08.log' size 500M;
alter database add logfile group 9 '/u01/oradata/orahom/redo09.log' size 500M;

alter database drop logfile group 6;
alter database add logfile group 6 '/u01/oradata/orahom/redo06.log' size 500M reuse;

alter database drop logfile group 3;
alter database add logfile group 3 '/u01/oradata/orahom/redo03.log' size 500M reuse;

alter database drop logfile group 7;
alter database add logfile group 7 '/u01/oradata/orahom/redo07.log' size 500M reuse;

alter database add logfile group 10 '/u01/oradata/orahom/redo10.log' size 500M reuse;

ALTER SYSTEM CHECKPOINT GLOBAL;


alter database drop logfile group 6;
alter database add logfile group 6 (
'+DGDATA/dbass/redo06a.log',
'+DGRECO/dbass/redo06b.log'
) size 500m reuse;


alter database add logfile group 5 '/u01/oradata/cdbhom/redo05.log' size 1024M reuse;


alter database add logfile group 2 (
'+DGREDOA/redolog/dbass/redo02a.log',  
'+DGREDOB/redolog/dbass/redo02b.log') size 100m reuse;

alter database add logfile group 3 (
'+DGREDOA/redolog/dbass/redo03a.log',  
'+DGREDOB/redolog/dbass/redo03b.log') size 100m reuse;

alter database add logfile group 4 (
'+DGREDOA/redolog/dbass/redo04a.log',  
'+DGREDOB/redolog/dbass/redo04b.log') size 100m reuse;

alter database add logfile group 5 (
'+DGREDOA/redolog/dbass/redo05a.log',  
'+DGREDOB/redolog/dbass/redo05b.log') size 100m reuse;

alter database add logfile group 6 (
'+DGREDOA/redolog/dbass/redo06a.log',  
'+DGREDOB/redolog/dbass/redo06b.log') size 100m reuse;

alter database add logfile group 7 (
'+DGREDOA/redolog/dbass/redo07a.log',  
'+DGREDOB/redolog/dbass/redo07b.log') size 100m reuse;

alter database add logfile group 8 (
'+DGREDOA/redolog/dbass/redo08a.log',  
'+DGREDOB/redolog/dbass/redo08b.log') size 100m reuse;


select group#,
       thread#,
       to_char(first_time,'DD/MM HH24:MI') TROCA_REDO,
       (BYTES /1024/1024) TAMANHO_MB
  FROM V$LOG ORDER BY 2, FIRST_TIME;