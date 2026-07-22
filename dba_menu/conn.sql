set lines 250 pages 999
col username for a30
col machine for a50
col program for a50
select inst_id,username,machine,program,status,count(*)
from gv$session
where
type='USER'
and username is not null
and username not in ('OPS$ORACLE','DBSNMP','SYSTEM','SYS','SYSRAC')
--and status='ACTIVE'
--and program like 'OMS'
--and username like 'SYSMAN%'
--and username  like '%ALT'
--and machine like 'prdplogrd001a%'
group by inst_id,username,machine,program,status
order by 3,1
/
