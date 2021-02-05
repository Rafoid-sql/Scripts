CREATE OR REPLACE TRIGGER trig_name
   BEFORE INSERT OR UPDATE OR DELETE ON username_1.table_1
DECLARE 
   v_sid        NUMBER; 
   v_program    VARCHAR2 (30); 
   v_username   VARCHAR2 (40); 
   v_sql_id     varchar2 (100); 
   v_machine    varchar2 (100); 
   v_terminal   varchar2 (100); 
   v_osuser     varchar2 (100); 
   v_sql_text   varchar2 (32600); 
BEGIN 
   select distinct sid into v_sid from sys.v_$mystat; 

   select sql_id into v_sql_id from v$session where sid = v_sid; 

   select sql_text from v$sqlarea where sql_id = v_sql_id;

   select program, OSUSER,username,terminal,machine,sql_id 
   INTO v_program, v_osuser, v_username,v_terminal, v_machine, v_sql_id 
   from sys.v_$session where sid = :b1'

if inserting then
insert into table_1 values(v_sid,v_program,v_username,v_sql_id, 
v_machine,v_terminal,v_osuser,v_sql_text,'insert'); 
end if;

if updating then
insert into table_1 values(v_sid,v_program,v_username,v_sql_id, 
v_machine,v_terminal,v_osuser,v_sql_text,'update'); 
end if;

end;
/