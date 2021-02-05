-- MOVENDO INDICE
select 'alter index '||owner|| '.'||index_name||' rebuild tablespace ACADEMICO_I;' CMD
FROM DBA_INDEXES 
WHERE INDEX_TYPE <> 'LOB' AND OWNER = 'DBAASS';

--MOVENDO LOB
select 'alter table '
	||t.owner
	|| '.'
	||t.table_name
	||' move lob ('
	|| column_name
	|| ') store as (tablespace ACADEMICO_BLOB);' CMD
	FROM DBA_LOBS l, dba_tables t
	WHERE l.owner = t.owner
	AND l.table_name = t.table_name
	AND l.segment_name in
			(select segment_name
				from dba_segments
				where segment_type = 'LOBSEGMENT'
						AND OWNER = 'DBAASS'
						AND tablespace_name = 'ACADEMICO')
	AND l.owner = 'DBAASS'
	ORDER BY t.owner, t.table_name;