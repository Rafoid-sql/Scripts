set lines 250 pages 999 verify off
col owner for a20
col object_name for a20
col table_name for a20
col created for a10
select do.owner,do.object_name, di.table_name,do.created,di.degree
from dba_objects do, dba_indexes di
where
do.owner=di.owner
and do.object_name=di.index_name
and do.object_type='INDEX'
and do.owner=upper('&1')
and (degree <> '1' and degree <> '0')
order by do.created;

undefine 1
