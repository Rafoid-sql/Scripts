SELECT STAT.OWNER AS "Schema proprietário",
         STAT. TABLE_NAME AS "Nome do objeto",
         STAT.OBJECT_TYPE AS "Tipo do objeto",
         STAT.NUM_ROWS AS "Quant. de Linhas",
         STAT.LAST_ANALYZED AS "Última coleta das estatísticas"
    FROM SYS.DBA_IND_STATISTICS STAT
   WHERE STAT.OWNER  IN ('DBAASS')
ORDER BY LAST_ANALYZED;



SELECT STAT.OWNER AS "Schema proprietário",
         STAT.TABLE_NAME AS "Nome do objeto",
         STAT.OBJECT_TYPE AS "Tipo do objeto",
         STAT.NUM_ROWS AS "Quant. de Linhas",
         STAT.LAST_ANALYZED AS "Última coleta das estatísticas"
    FROM SYS.DBA_TAB_STATISTICS STAT
   WHERE STAT.OWNER IN ('DBAASS')
ORDER BY LAST_ANALYZED;

-- 
SELECT --STAT.OWNER AS "Schema proprietário",
         STAT.TABLE_NAME AS "Nome do objeto",
         STAT.OBJECT_TYPE AS "Tipo do objeto",
         STAT.NUM_ROWS AS "Quant. de Linhas",
         STAT.LAST_ANALYZED AS "Última coleta das estatísticas",
         (MOD.INSERTS+MOD.UPDATES+MOD.DELETES) AS TOTAL_DML,
         round(((MOD.INSERTS+MOD.UPDATES+MOD.DELETES)/STAT.NUM_ROWS*100),2) AS PCT_DML,
         MOD.timestamp
    FROM SYS.DBA_TAB_STATISTICS STAT, DBA_TAB_MODIFICATIONS MOD
   WHERE STAT.OWNER IN ('DBAASS')
   AND STAT.TABLE_NAME = MOD.TABLE_NAME
   AND STAT.LAST_ANALYZED < SYSDATE - 3
  -- and STAT.table_name IN ('GRADE_SEMESTRE')
ORDER BY LAST_ANALYZED;

begin
      sys.dbms_stats.gather_table_stats(ownname          => 'DBAASS',
                                        tabname          => 'ACAO_MKT_PESSOA',
                                        estimate_percent => 100,
                                        method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
                                        granularity      => 'ALL',
                                        cascade          => TRUE,
                                        no_invalidate    => FALSE,
                                        DEGREE           => 4);
end;  
/

begin
      sys.dbms_stats.gather_table_stats(ownname          => 'SYS',
                                        tabname          => 'OBJ$',
                                        estimate_percent => 33,
                                        method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
                                        granularity      => 'ALL',
                                        cascade          => TRUE,
                                        no_invalidate    => FALSE,
                                        DEGREE           => 4);
end;
/