set lines 250 pages 999 verify off
select * from table(dbms_xplan.display_awr('&1',null));
