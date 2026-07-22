set lines 250 pages 999 verify off
col index_owner for a30
col index_name for a30
col column_name for a30
break on index_owner on index_name skip 1
select ic.index_owner,ic.index_name,uniqueness unq,column_name,column_position 
from dba_ind_columns ic, dba_indexes i
where 
ic.index_owner=i.owner
and ic.index_name=i.index_name
and i.owner=upper('&table_owner') 
and i.table_name=upper('&table_name') 
and i.uniqueness='UNIQUE'
order by index_owner,index_name,column_position;
