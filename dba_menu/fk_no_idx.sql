set lines 250 pages 999 verify off
col owner for a30
col table_name for a25
col column_name for a30
    SELECT c.owner,c.table_name, cc.column_name, cc.position column_position
    FROM   dba_constraints c, dba_cons_columns cc
    WHERE  c.constraint_name = cc.constraint_name
    AND    c.owner = cc.owner
    AND    c.constraint_type = 'R'
    AND    c.owner=upper('&&1')
    MINUS
    SELECT i.owner,i.table_name, ic.column_name, ic.column_position
    FROM   dba_indexes i, dba_ind_columns ic
    WHERE  i.index_name = ic.index_name
    AND    i.owner = ic.index_owner
    AND    i.owner = upper('&1')
ORDER BY owner,table_name, column_position;

undefine 1
