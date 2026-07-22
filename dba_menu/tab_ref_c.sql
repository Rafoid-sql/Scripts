set lines 250 pages 999 verify off
col owner for a20
col table_name for a25
col constraint_name for a20
col r_constraint_name for a20
col column_name for a25
col type for a2
col r_owner for a20
col delete_rule for a10

prompt table referential constraint info...
select c.owner,c.table_name,c.constraint_name,cc.column_name,c.constraint_type type,r_owner,r_constraint_name,delete_rule
from dba_cons_columns cc, dba_constraints c
where cc.owner=c.owner
and cc.table_name=c.table_name
and cc.constraint_name=c.constraint_name
and c.owner=upper('&&1')
and c.table_name=upper('&&2')
and c.constraint_type='R'
order by c.owner,c.table_name,c.constraint_name,cc.column_name
/


set lines 250 pages 999
col owner for a20
col table_name for a20
col constraint_name for a20
col r_constraint_name for a20
col column_name for a20
col type for a2
col r_owner for a20
col index_owner for a20
col index_name for a20
col delete_rule for a10

prompt referential constraint info...
with ref_cons as
(
select r_owner,r_constraint_name
from dba_cons_columns cc, dba_constraints c
where 
cc.owner=c.owner
and cc.table_name=c.table_name
and cc.constraint_name=c.constraint_name
and c.owner=upper('&1')
and c.table_name=upper('&2')
and c.constraint_type='R'
)
select c.owner,c.table_name,c.constraint_name,cc.column_name,c.constraint_type type,delete_rule,c.index_owner,c.index_name
from dba_cons_columns cc, dba_constraints c, ref_cons r
where 
cc.owner=c.owner
and cc.table_name=c.table_name
and cc.constraint_name=c.constraint_name
and c.owner=r.r_owner
and c.constraint_name=r.r_constraint_name
order by c.owner,c.table_name,c.constraint_name,cc.column_name
/

undefine 1
undefine 2
