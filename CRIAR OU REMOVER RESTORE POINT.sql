-- ----------------------------------------------------------------------------------------
-- Nome do Arquivo    : create_restore_point.sql
-- Autor              : Guilherme Weiss Caldeira
-- Descrição          : Cria um ponto de restauração para o banco de dados.
-- Última Modificação : 09/08/2019
-- Notas              : 
-- ----------------------------------------------------------------------------------------

-- Validar se o recurso de flashback está habilitado:

SELECT flashback_on, log_mode FROM v$database;

-- Consultar os valores definidos para os parâmetros 'db_recovery_file_dest_size' e 'db_recovery_file_dest':

SHOW PARAMETER db_recovery_file_dest

-- Exemplo de Alteração:

ALTER SYSTEM SET db_recovery_file_dest='/orabackup/tasy/' SCOPE = BOTH;

ALTER SYSTEM SET db_recovery_file_dest_size = 300G SCOPE = BOTH;

ALTER DATABASE FLASHBACK ON;

-- Criar um restore point:

CREATE RESTORE POINT ATUALIZA20200316 GUARANTEE FLASHBACK DATABASE;

-- Verificar se o restore point foi criado:

SET LINES 300
COL name FOR A40
COL storage_size FOR '9,999,990.00'
COL scn FOR '99999999999999999999999999'
SELECT name, guarantee_flashback_database, storage_size /1024 /1024 AS storage_size_mb, TO_CHAR(time, 'dd/mm/yyyy hh24:mi:ss') AS time, scn FROM v$restore_point;

-- Após término dos processos de manutenção com sucesso, deve-se remover o restore point, conforme instrução abaixo:

DROP RESTORE POINT ATUALIZA20200316;


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