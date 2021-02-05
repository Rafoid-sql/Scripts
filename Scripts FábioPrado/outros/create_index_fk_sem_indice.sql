col constraint_name for a55
col table_name for a55
col columns for a55
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/create_index.sql
select 'CREATE INDEX DBAASS.I_'||substr(constraint_name,0,28)||' ON '||'DBAASS.'||table_name||'('||columns||') TABLESPACE ' || DECODE(INSTR(table_name, 'OLI_'), 0, 'ACADEMICO_I', 'ACADEMICO_OLIMPO_I') || ';' indice
from
(
select owner, table_name, constraint_name,
    cname1 || nvl2(cname2,','||cname2,null) ||
    nvl2(cname3,','||cname3,null) || nvl2(cname4,','||cname4,null) ||
    nvl2(cname5,','||cname5,null) || nvl2(cname6,','||cname6,null) ||
    nvl2(cname7,','||cname7,null) || nvl2(cname8,','||cname8,null)
           columns
 from ( select b.owner,
         b.table_name,
               b.constraint_name,
               max(decode( position, 1, column_name, null )) cname1,
               max(decode( position, 2, column_name, null )) cname2,
               max(decode( position, 3, column_name, null )) cname3,
               max(decode( position, 4, column_name, null )) cname4,
               max(decode( position, 5, column_name, null )) cname5,
               max(decode( position, 6, column_name, null )) cname6,
               max(decode( position, 7, column_name, null )) cname7,
               max(decode( position, 8, column_name, null )) cname8,
               count(*) col_cnt
          from (select substr(owner,1,30) owner,
             substr(table_name,1,30) table_name,
                       substr(constraint_name,1,30) constraint_name,
                       substr(column_name,1,30) column_name,
                       position
                  from dba_cons_columns ) a,
               dba_constraints b,
               dba_tables t
         where a.constraint_name = b.constraint_name
           and a.owner = b.owner
           and a.table_name = t.table_name
           --and t.num_rows > 9000
           and b.constraint_type = 'R'
		   and b.constraint_type != 'U'
           and b.owner = 'DBAASS'
           and b.table_name  like 'OLI_%'
         group by b.owner,b.table_name, b.constraint_name
      ) cons
where col_cnt > ALL
        ( select count(*)
            from dba_ind_columns i
           where i.table_name = cons.table_name
             and i.column_name in (cname1, cname2, cname3, cname4,
                                   cname5, cname6, cname7, cname8 )
             and i.column_position <= cons.col_cnt
           group by i.index_name
        )
);
SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off