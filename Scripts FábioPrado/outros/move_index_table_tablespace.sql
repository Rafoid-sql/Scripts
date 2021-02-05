
select 'alter table '
||owner
||'.'
|| table_name
||' move tablespace ACADEMICO_OLIMPO;' 
FROM DBA_TABLES
WHERE
OWNER = 'DBAASS'
AND TABLE_NAME LIKE 'OLI%'


select 'alter INDEX '
||owner
||'.'
|| index_name
||' rebuild tablespace ACADEMICO_OLIMPO_I;' 
FROM DBA_INDEXES

select 'alter INDEX '
||owner
||'.'
|| index_name
||' rebuild;' 
FROM DBA_INDEXES
where  OWNER NOT IN ('SYS','SYSTEM')
 AND status != 'VALID'