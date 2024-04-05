--KILLING SESSIONS

-----------------
--SINGLE INSTANCE
-----------------

--SINGLE USER:
BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where username = 'SOLUS' AND STATUS !='KILLED')
   LOOP
   	execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''';
   END LOOP;
END;
/

BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where program = 'dllhost.exe')
   LOOP
   	execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'' IMMEDIATE';
   END LOOP;
END;
/

--PARA SERCOMTEL (BACKUP OFFLINE):
BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where username is not null and username != 'SYS' and username != 'BACKUP')
   LOOP
   	execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||''' IMMEDIATE';
   END LOOP;
END;
/

--OSUSER
BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where osuser = 'nagios' and sql_id='8c53xcd1mmq86')
   LOOP
   	--execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''';
   	DBMS_OUTPUT.PUT_LINE('ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''');
   END LOOP;
END;
/

--MACHINE, AMAZON RDS
BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where machine = 'ip-172-31-52-193.sa-east-1.compute.internal')
   LOOP
   	rdsadmin.rdsadmin_util.kill(SESS.sid, SESS.serial#); 
   	--DBMS_OUTPUT.PUT_LINE('ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''');
   END LOOP;
END;
/

--RAC

begin     
    for x in (  
            select sid,serial#,username,machine,inst_id from gv$session  
            where  
                machine <> 'MyDatabaseServerName'  
        ) loop  
        execute immediate 'Alter System Kill Session '''|| x.Sid  
                     || ',' || x.Serial# || ''' IMMEDIATE';  
    end loop;  
end;



BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where username = 'TOTVS')
   LOOP
   	execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||''' IMMEDIATE';
   END LOOP;
END;
/




BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where username = 'SPED' AND STATUS !='KILLED')
   LOOP
    execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''';
   END LOOP;
END;
/

BEGIN
   FOR SESS IN (select SID, SERIAL# from v$session where username = 'TOTVS' AND STATUS !='KILLED')
   LOOP
    execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''';
   END LOOP;
END;
/


--OSUSER
BEGIN
   FOR SESS IN (select SID, SERIAL# from gv$session where username = 'SYSTEM' and sql_id='argb99bwmfdkf')
   LOOP
   	--execute immediate 'ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||'''';
   	DBMS_OUTPUT.PUT_LINE('ALTER SYSTEM KILL SESSION '''||SESS.sid||','||SESS.serial#||',@'||SESS.inst_id||'''');
   END LOOP;
END;
/


--DROP USER

/*BEGIN
   FOR USUARIO IN (select username from dba_users where default_tablespace in ('MV2000_A','MV2000_AI','MV2000_D','MVCARTORIO_D','MVPORTAL_D','SGPS_D') and username not in ('LB2BKP','DIP','ORACLE_OCM','XS$NULL') and username not like ('%APEX%'))
   LOOP
   	execute immediate 'DROP USER "'||USUARIO.username||'" cascade';
   	DBMS_OUTPUT.PUT_LINE('DROP USER "'||USUARIO.username||'" cascade');
   END LOOP;
END;
/ */


