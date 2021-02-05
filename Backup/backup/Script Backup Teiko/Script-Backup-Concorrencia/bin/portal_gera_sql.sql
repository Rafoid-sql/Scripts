set term off feedback off verify off pages 0 lines 2000 trimspool on head off
SPOOL '/home/oracle/scripts/bin/PORTAL_REMOVE_ARCHIVES.sh';
select 'asmcmd rm +data/portal/archivelog/'||B.NAME
from v$asm_file a
join v$asm_alias b on (a.group_number = b.group_number and
                       a.file_number = b.file_number)
where a.type = 'ARCHIVELOG' and b.name like '%983110059.arc'
and to_date(a.creation_date) = to_date(sysdate)-10
order by 1;
SPOOL off;
exit

