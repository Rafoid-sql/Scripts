-- ----------------------------------------------------------------------------------------
-- Nome do Arquivo    : flashback_db.sql
-- Autor              : Guilherme Weiss Caldeira
-- Descrição          : Realiza o flashback do banco de dados.
-- Última Modificação : 09/08/2019
-- Notas              : 
-- ----------------------------------------------------------------------------------------

-- Consultar o restore point ao qual será utilizado:

SET LINES 200
COL name FOR A40
COL storage_size FOR '9,999,990.00'
COL scn FOR '99999999999999999999999999'

SELECT
  name
  , guarantee_flashback_database
  , storage_size /1024 /1024 AS storage_size_mb
  , TO_CHAR(time, 'dd/mm/yyyy hh24:mi:ss') AS time
  , scn
FROM v$restore_point;

-- Desligar o banco de dados:

SHUTDOWN IMMEDIATE;

-- Montar o banco de dados:

STARTUP MOUNT;

-- Realizar o flashback do banco de dados:

FLASHBACK DATABASE TO RESTORE POINT nome_restore_point;

-- Abrir o banco de dados com 'resetlogs':

ALTER DATABASE OPEN RESETLOGS;