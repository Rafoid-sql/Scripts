set lines 250 pages 999 verify off
col owner for a20
col table_name for a25
col constraint_name for a20
col r_constraint_name for a20
col column_name for a25
col type for a2
col r_owner for a20
col delete_rule for a10

select c.owner,c.table_name,c.constraint_name,cc.column_name,c.constraint_type type,r_owner,r_constraint_name,delete_rule
from dba_cons_columns cc, dba_constraints c
where cc.owner=c.owner
and cc.table_name=c.table_name
and cc.constraint_name=c.constraint_name
and c.owner=upper('&1')
and c.table_name=upper('&2')
/

undefine 1
undefine 2
