set lines 250 pages 999
col sql for a100
SELECT substr(sql_text,1,80) "SQL",
         count(*) ,
         sum(executions) "TotExecs"
    FROM gv$sqlarea
   WHERE executions < 5
   GROUP BY substr(sql_text,1,80)
  HAVING count(*) > 30
   ORDER BY 2
  ;
