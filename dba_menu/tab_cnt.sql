set lines 250 pages 999 verify off
select /*+ parallel(2) */ count(*), count(distinct &col_name) from &owner..&tab_name;

undefine tab_name
undefine owner
undefine col_name

