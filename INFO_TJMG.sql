========================================================================================

### ORDEM DE ATUACAO ###
IN > MDT > RS

========================================================================================

### COMANDO SCRIPT AUTOMACAO ###
sh pre-pos_restore_pje/exec_chamados_postgres.sh MDT1013850 PJE P0102637

========================================================================================

### ADICIONAR ANTES DO SCRIPT ###
select 'Banco de dados: '||current_database() "Banco de dados";

========================================================================================

### ACERTAR CHARSET ###
iconv -c -f utf-8 -t iso-8859-1 MDT1013836.sql > MDT1013836_iso.sql && mv MDT1013836_iso.sql MDT1013836.sql

========================================================================================

### PJE RECURSAL ###
psql -U postgres -p 5432 -w -d pjerecursal < MDT1013809.sql >> MDT1013809.log 2>&1

### PJE ###
psql -U postgres -p 5432 -w -d pje <  MDT1013843.sql >>  MDT1013843.log 2>&1

========================================================================================

### RECOMPILAR OBJETOS ###
EXEC UTL_RECOMP.RECOMP_SERIAL ('DBATJ','THEMIS2G','RUPE');

### VERIFICAR INVÁLIDOS ###
SELECT owner, object_type, object_name, status
FROM dba_objects
WHERE status = 'INVALID'
and owner in ('DBATJ','THEMIS2G','RUPE')
ORDER BY owner, object_type, object_name;



========================================================================================

### Consulta Transaçoes IDLE ###
select count(*), state from pg_stat_activity where datname='pje' group by state;

### Encerra sessoes idle ###

select pg_terminate_backend(pid) from pg_stat_activity where state = 'idle in transaction'  and datname = 'pje';