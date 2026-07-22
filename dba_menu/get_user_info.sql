set serveroutput on size 50000
set echo off feed off veri off

DECLARE
  v_user dba_users.username%type;
  v_sql varchar2(1000);
  v_ora char(1);
  v_last_login date;
  v_version number;
  u dba_users%ROWTYPE;
  p sys.user$%ROWTYPE;
BEGIN
  begin
    select username into v_user
    from   dba_users
    where
      username = upper('&1');

  select to_number(substr(version,1,2)) into v_version
  from v$instance;

  exception
    when no_data_found then
      dbms_output.put_line('Unable to find username &&1!!!');
      return;
    when others then
      dbms_output.put_line(sqlerrm);
      return;
  end;

  select * into u from dba_users where username = v_user;
  select * into p from sys.user$ where name = v_user;

  if v_version > 11 then
   v_sql := 'select oracle_maintained,last_login from dba_users where username = :v_user';
   execute immediate v_sql into v_ora,v_last_login using v_user;
  end if;

  dbms_output.put_line('=====================================================================');
  dbms_output.put_line('Username  	: '|| u.username);
  dbms_output.put_line('Account Status  : '|| u.account_status);
  dbms_output.put_line('Profile  	: '|| u.profile);
  dbms_output.put_line('Def Tablespace 	: '|| u.default_tablespace);
  dbms_output.put_line('Temp Tablespace : '|| u.temporary_tablespace);
  dbms_output.put_line('Password Version: '|| u.password_versions);
  dbms_output.put_line('Auth Type       : '|| u.authentication_type);
  dbms_output.put_line('Lock Counter    : '|| p.lcount);
  dbms_output.put_line('Created 	: '|| to_char(u.created, 'MM/DD/YYYY HH24:MI:SS'));
  dbms_output.put_line('Last Lock Time  : '|| to_char(p.ltime, 'MM/DD/YYYY HH24:MI:SS'));
  dbms_output.put_line('Last Expiry Time: '|| to_char(p.exptime, 'MM/DD/YYYY HH24:MI:SS'));
  dbms_output.put_line('Password Changed: '|| to_char(p.ptime, 'MM/DD/YYYY HH24:MI:SS'));
  dbms_output.put_line('Oracle Maintain : '|| v_ora);
  dbms_output.put_line('Last Login      : '|| to_char(v_last_login,'MM/DD/YYYY HH24:MI:SS'));
  dbms_output.put_line('=====================================================================');
END;
/

undef 1
set echo off feed on veri on
