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
   WHERE STAT.OWNER IN ('SYS')
ORDER BY LAST_ANALYZED;