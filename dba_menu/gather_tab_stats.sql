set verify off echo on lines 250 pages 999

exec dbms_stats.gather_table_stats(ownname=>'&schema_name', tabname => '&table_name', estimate_percent=>dbms_stats.auto_sample_size, cascade=>TRUE, method_opt=>'FOR ALL COLUMNS SIZE 1', degree => 4, no_invalidate => FALSE);
