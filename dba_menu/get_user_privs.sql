--whenever sqlerror exit rollback
set feed on
set head on
set arraysize 1
set space 1
set verify off
set pages 25
set lines 200
set termout on
--clear screen
set serveroutput on size 1000000

--spool find_all_privs.lis

set feed off
col system_date noprint new_value val_system_date

select to_char (sysdate, 'Dy Mon dd hh24:mi:ss yyyy') system_date from sys.dual;

set feed on

declare
   --
   lv_tabs             number := 0;
   lg_fptr             utl_file.file_type;
   lv_file_or_screen   varchar2 (1) := 'S';
   examine_tables      varchar2 (1) := 'Y';

   procedure write_op (pv_str in varchar2) is
    begin
        if lv_file_or_screen='S' then
            dbms_output.put_line(pv_str);
        end if;
    exception
        when others then
            dbms_output.put_line('ERROR (write_op) => '||sqlcode);
            dbms_output.put_line('MSG (write_op) => '||sqlerrm);

    end write_op;

   procedure get_privs (pv_grantee in varchar2, lv_tabstop in out number)
   is
      --
      lv_tab    varchar2 (50) := null;
      lv_loop   number;

      --
      cursor c_main (
         cp_grantee in varchar2)
      is
	-- the hint is commented out as David got an ORA-12801 and an ORA-00600 because of the 
	-- hint. You can try the hint, if it works, then fine, if not comment out
--           select /*+ PARALLEL a */
           select
                 a.*
             from (select 'ROLE' typ,
                          grantee grantee,
                          granted_role priv,
                          admin_option ad,
                          '--' tabnm,
                          '--' colnm,
                          '--' owner,
                          r.password_required pwd
                     from dba_role_privs rp join dba_roles r on rp.granted_role = r.role
                    where grantee = cp_grantee
                   union
                   select 'SYSTEM' typ,
                          grantee grantee,
                          privilege priv,
                          admin_option ad,
                          '--' tabnm,
                          '--' colnm,
                          '--' owner,
                          '--' pwd
                     from dba_sys_privs
                    where grantee = cp_grantee
                   union
                   select 'TABLE' typ,
                          grantee grantee,
                          privilege priv,
                          grantable ad,
                          table_name tabnm,
                          '--' colnm,
                          owner owner,
                          '--' pwd
                     from dba_tab_privs
                    where grantee = cp_grantee and 'Y' = 'Y'
                   union
                   select 'COLUMN' typ,
                          grantee grantee,
                          privilege priv,
                          grantable ad,
                          table_name tabnm,
                          column_name colnm,
                          owner owner,
                          '--' pwd
                     from dba_col_privs
                    where grantee = cp_grantee and 'Y' = 'Y') a
         order by case
                     when a.typ = 'ROLE' then 4
                     when a.typ = 'SYSTEM' then 1
                     when a.typ = 'TABLE' then 2
                     when a.typ = 'COLUMN' then 3
                     else 5
                  end,
                  case when a.priv in ('EXECUTE') then 1 when a.priv in ('SELECT', 'UPDATE', 'INSERT', 'DELETE') then 3 else 2 end,
                  a.tabnm,
                  a.colnm,
                  a.priv;

   begin
      lv_tabstop := lv_tabstop + 1;

      for lv_loop in 1 .. lv_tabstop
      loop
         lv_tab := lv_tab || chr (9);
      end loop;

      for lv_main in c_main (pv_grantee)
      loop
         if lv_main.typ = 'ROLE' then
            write_op (
                  lv_tab
               || 'ROLE => '
               || lv_main.priv
               || case when lv_main.pwd = 'YES' then ' (password)' else null end
               || ' which contains =>');
            get_privs (lv_main.priv, lv_tabstop);
         elsif lv_main.typ = 'SYSTEM' then
            write_op (lv_tab || 'SYS PRIV => ' || lv_main.priv || ' grantable => ' || lv_main.ad);
         elsif lv_main.typ = 'TABLE' then
            write_op (
                  lv_tab
               || 'TABLE PRIV => '
               || lv_main.priv
               || ' object => '
               || lv_main.owner
               || '.'
               || lv_main.tabnm
               || ' grantable => '
               || lv_main.ad);
         elsif lv_main.typ = 'COLUMN' then
            write_op (
                  lv_tab
               || 'COL PRIV => '
               || lv_main.priv
               || ' object => '
               || lv_main.owner
               || '.'
               || lv_main.tabnm
               || ' column_name => '
               || lv_main.colnm
               || ' grantable => '
               || lv_main.ad);
         end if;
      end loop;

      lv_tabstop := lv_tabstop - 1;
      lv_tab := '';
   exception
      when others then
         dbms_output.put_line ('ERROR (get_privs) => ' || sqlcode);
         dbms_output.put_line ('MSG (get_privs) => ' || sqlerrm);
   end get_privs;

begin
   lv_file_or_screen := upper ('S');

   write_op (
      'User => ' || upper ('&&1') || ' has been granted the following privileges');
   write_op ('====================================================================');
   get_privs (upper ('&&1'), lv_tabs);

exception
   when others then
      dbms_output.put_line ('ERROR (main) => ' || sqlcode);
      dbms_output.put_line ('MSG (main) => ' || sqlerrm);
end;
/

prompt
--spool off

whenever sqlerror continue
