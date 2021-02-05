EXEC DBMS_STATS.GATHER_DATABASE_STATS(ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE,OPTIONS=>'GATHER STALE',BLOCK_SAMPLE=>FALSE,DEGREE=>6,GRANULARITY=>'AUTO',CASCADE=>TRUE,GATHER_SYS=>FALSE,NO_INVALIDATE=>FALSE,METHOD_OPT=>'FOR ALL COLUMNS SIZE AUTO');


EXEC DBMS_STATS.GATHER_DATABASE_STATS(ESTIMATE_PERCENT=>DBMS_STATS.AUTO_SAMPLE_SIZE,OPTIONS=>'GATHER EMPTY',BLOCK_SAMPLE=>FALSE,DEGREE=>6,GRANULARITY=>'AUTO',CASCADE=>TRUE,GATHER_SYS=>FALSE,NO_INVALIDATE=>FALSE,METHOD_OPT=>'FOR ALL COLUMNS SIZE AUTO');



declare

cursor c01 is
  SELECT object_name
    FROM user_objects
   WHERE object_type = 'TABLE'
     AND object_name LIKE 'MGR_%'
UNION ALL
  SELECT object_name
    FROM user_objects
   WHERE object_type = 'TABLE'
     AND object_name LIKE 'OLI_%';

begin

for r_c01 in c01 loop

   DBMS_STATS.GATHER_TABLE_STATS('DBAASS', r_c01.object_name, estimate_percent => 100, method_opt => 'FOR ALL COLUMNS SIZE AUTO', granularity => 'ALL', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);
end loop;

end;
/


====================================

declare

cursor cur01 is
	SELECT TABLE_NAME
		FROM dba_tab_statistics
	where owner IN ('DBAASS')
    and LAST_ANALYZED < SYSDATE - 3
	and num_rows > 20000000;
	
begin
	for r_cur01 in cur01 loop
			dbms_stats.gather_table_stats('DBAASS', r_cur01.TABLE_NAME, estimate_percent => 100, method_opt => 'FOR ALL COLUMNS SIZE AUTO', granularity => 'ALL', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);
	end loop;
end;
/

exec sys.dbms_stats.gather_table_stats(owname => 'DBAASS', tabname => 'ACAO_MKT_PESSOA', estimate_percent => 100, method_opt => 'FOR ALL COLUMNS SIZE AUTO', granularity => 'ALL', cascade => TRUE, no_invalidate => FALSE, DEGREE => 4);


