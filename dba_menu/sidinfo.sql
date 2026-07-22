rem -----------------------------------------------------------------------
rem Filename:   sidinfo.sql
rem Purpose:    Lookup database details for a given SID
rem -----------------------------------------------------------------------

set serveroutput on size 50000
set echo off feed off veri off
rem accept 1 prompt 'Enter Unix process id: '

DECLARE
  v_sid number;
  s v$session%ROWTYPE;
  p v$process%ROWTYPE;
BEGIN
  begin
    select s.sid into v_sid
    from   v$process p, v$session s
    where  
        p.addr     = s.paddr
        and s.sid = &1;
--      and  (p.spid    = &1
--       or   s.process = '&1');
  exception
    when no_data_found then
      dbms_output.put_line('Unable to find SID: &&1!!!');
      return;
    when others then
      dbms_output.put_line(sqlerrm);
      return;
  end;

  select * into s from v$session where sid  = v_sid;
  select * into p from v$process where addr = s.paddr;

  dbms_output.put_line('=====================================================================');
  dbms_output.put_line('SID/Serial  : '|| s.sid||','||s.serial#);
  dbms_output.put_line('Foreground  : '|| 'PID: '||s.process||' - '||s.program);
  dbms_output.put_line('Shadow      : '|| 'PID: '||p.spid||' - '||p.program);
  dbms_output.put_line('Terminal    : '|| s.terminal || '/ ' || p.terminal);
  dbms_output.put_line('OS User     : '|| s.osuser||' on '||s.machine);
  dbms_output.put_line('Ora User    : '|| s.username);
  dbms_output.put_line('Status Flags: '|| s.status||' '||s.server||' '||s.type);
  dbms_output.put_line('Tran Active : '|| nvl(s.taddr, 'NONE'));
  dbms_output.put_line('Event       : '|| nvl(s.event, 'NONE'));
  dbms_output.put_line('Sess State  : '|| nvl(s.state, 'NONE'));
  dbms_output.put_line('Blk Instance: '|| nvl(to_char(s.blocking_instance),'NONE'));
  dbms_output.put_line('Blk Session : '|| nvl(to_char(s.blocking_session),'NONE'));
  dbms_output.put_line('Login Time  : '|| to_char(s.logon_time, 'Dy HH24:MI:SS'));
  dbms_output.put_line('Last Call   : '|| to_char(sysdate-(s.last_call_et/60/60/24), 'Dy HH24:MI:SS') || ' - ' || to_char(s.last_call_et/60,'99990.0') || ' min');
  dbms_output.put_line('Sec in Wait : '|| to_char(s.seconds_in_wait)||' sec');
  dbms_output.put_line('Lock/ Latch : '|| nvl(s.lockwait, 'NONE')||'/ '||nvl(p.latchwait, 'NONE'));
  dbms_output.put_line('Latch Spin  : '|| nvl(p.latchspin, 'NONE'));

  dbms_output.put_line('Current SQL statement:');
  dbms_output.put_line(chr(9)||'SQL_ID : '||s.sql_id);
  for c1 in ( select * from v$sqltext
              where HASH_VALUE = s.sql_hash_value order by piece) loop
    dbms_output.put_line(chr(9)||c1.sql_text);
  end loop;

  dbms_output.put_line('Previous SQL statement:');
  dbms_output.put_line(chr(9)||'Prev SQL_ID : '||s.prev_sql_id);
  for c1 in ( select * from v$sqltext
              where HASH_VALUE = s.prev_hash_value order by piece) loop
    dbms_output.put_line(chr(9)||c1.sql_text);
  end loop;

  dbms_output.put_line('=====================================================================');

END;
/

undef 1
set echo off feed on veri on
