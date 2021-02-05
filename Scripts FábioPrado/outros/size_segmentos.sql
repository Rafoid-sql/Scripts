set lines 155
set pagesize 10000
select 'alter index '||OWNER||'.'||index_name||' rebuild tablespace ACADEMICO_I;'
   from dba_indexes 
   where OWNER = 'DBAASS'
   AND INDEX_TYPE NOT IN ('LOB') 
   AND tablespace_name!='ACADEMICO_I'
   
   
   --TAMANHOS DOS SEGMENTOS DE INDICE A SER MOVIDO
   
   SELECT OWNER, SUM(BYTES/1024/1024) FROM DBA_SEGMENTS
   where OWNER not in ('SYS','SYSTEM','DBSNMP','OUTLN','WMSYS','GSMADMIN_INTERNAL','XDB','RMAN',
                        'TEIKOBKP','TEIKOADM','FAROL','PERFSTAT')
      AND SEGMENT_TYPE = 'INDEX'
     GROUP BY (OWNER)
     ORDER BY 1
    