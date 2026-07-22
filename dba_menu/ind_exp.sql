set lines 250 pages 999 verify off
col table_name for a32
col index_name for a32
col column_name for a32
col column_expression for a50
col pos for 99
break on table_name on index_name skip 1
select table_name,index_name,column_position pos,column_expression
from dba_ind_expressions
where index_owner=upper('&1') 
and table_name=upper('&2') 
order by index_owner,index_name,column_position;

undefine 1
undefine 2
