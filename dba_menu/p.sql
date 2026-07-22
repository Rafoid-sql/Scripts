set lines 250 pages 999 verify off
select * from table(dbms_xplan.display_cursor('&1',null));
