
--1 - Desligar o banco:
SHUTDOWN IMMEDIATE

--2 - Reiniciar em modo restrito:
STARTUP RESTRICT

--3 - Invalidar objetos do banco:
@/orabin01/app/oracle/product/11.2.0.4/dbhome_1/rdbms/admin/utlip.sql

--4 - Revalidar objetos do banco:
@/orabin01/app/oracle/product/11.2.0.4/dbhome_1/rdbms/admin/utlrp.sql

--5 - Coletar estatísticas:
EXEC DBMS_STATS.GATHER_DICTIONARY_STATS;