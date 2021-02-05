select 'ALTER INDEX '  
        || OWNER
		||'.'
    ||index_name
    ||' REBUILD '
     from 
       dba_indexes 
   where owner NOT in ('SYS', 'SYSTEM')
       AND STATUS != 'VALID' 
     
========================================================================
	   

	   
	   select  OWNER
        , INDEX_NAME
        , INDEX_TYPE
        , TABLE_NAME
        , TABLESPACE_NAME
        , STATUS 
   from 
       dba_indexes 
   where owner in ('DBAASS','POS_EAD')
       AND TABLESPACE_NAME != 'ACADEMICO_I' 
       AND INDEX_TYPE != 'LOB'
	   
==============================================================================
	   
	  -- ALTER INDEX nome_do_indice REBUILD TABLESPACE nome_do_novo_tablespace
	   
	   SELECT 'ALTER TABLE ' 
    || t.owner 
    || '.' 
    || t.table_name 
    || ' MOVE LOB (' 
    || column_name  
    || ') STORE AS (TABLESPACE ACADEMICO_BLOB);'  
    FROM dba_lobs l, dba_tables t
    where l.owner = t.owner
        and l.table_name = t.table_name
    and l.segment_name in 
        (select segment_name  
          from dba_segments
          where segment_type = 'LOBSEGMENT'
            AND TABLESPACE_NAME != 'ACADEMICO_BLOB' 
            and l.owner in ('DBAASS','POS_EAD'))
        ORDER BY t.owner, t.table_name;