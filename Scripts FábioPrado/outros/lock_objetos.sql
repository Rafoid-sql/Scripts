
set term on;
set lines 150;
set linesize 255;
column sid_ser format a12 heading 'Session,|Serial#';
column username format a30 heading 'OS User/|DB User';
column spid format a7 heading 'OS|Process';
column owner_object format a35 heading 'Owner.Object';
column locked_mode format a13 heading 'Locked|Mode';
column status format a8 heading 'Status';
column logon format a18 heading 'Date|Logon';

select
    substr(to_char(l.session_id)||','||to_char(s.serial#),1,12) sid_ser,
    substr(l.os_user_name||'/'||l.oracle_username,1,12) username,
    p.spid,
    substr(o.owner||'.'||o.object_name,1,35) Owner_object,
    decode(l.locked_mode,
             1,'No Lock',
             2,'Row Share',
             3,'Row Exclusive',
             4,'Share',
             5,'Share Row Excl',
             6,'Exclusive',null) Locked_mode,
    substr(s.status,1,8) Status,
    to_char(s.LOGON_TIME,'dd/mm/yyyy hh24:mi') logon
from
    v$locked_object l,
    all_objects     o,
    v$session       s,
    v$process       p
where
    l.object_id = o.object_id
and l.session_id = s.sid
and s.paddr      = p.addr
/
