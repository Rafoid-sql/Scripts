
begin
exec dbms_network_acl_admin.create_acl(
acl => 'uniasselvi', 
host => '*.uniasselvi.com.br', 
principal => 'DBAASS', 
lower_port => 80, 
upper_port => 80,  
is_grant => TRUE, 
privilege => 'connect');
end;




SELECT HOST, LOWER_PORT, UPPER_PORT,
       ACE_ORDER, PRINCIPAL, PRINCIPAL_TYPE,
       GRANT_TYPE, INVERTED_PRINCIPAL, PRIVILEGE,
       START_DATE, END_DATE
  FROM DBA_HOST_ACES ACES
  ORDER BY LOWER_PORT NULLS LAST,
          UPPER_PORT NULLS LAST,
          ACE_ORDER;
		  
		  
BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl=>'uniasselvi',
                                    description=>'WWW ACL',
                                    principal=>'DBAASS',
                                    is_grant=>true,
                                    privilege=>'connect');							
end;
/
 BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl       => 'uniasselvi',
                                       principal => 'DBAASS',
                                       is_grant  => true,
                                       privilege => 'resolve');
 
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl  => 'uniasselvi',
                                    host => '*.uniasselvi.com.br');
END;
/
COMMIT;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl=>'uniasselvi3',
                                    description=>'WWW ACL',
                                    principal=>'DBAASS',
                                    is_grant=>true,
                                    privilege=>'connect');							
end;
/
 BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl       => 'uniasselvi3',
                                       principal => 'DBAASS',
                                       is_grant  => true,
                                       privilege => 'resolve');
 
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl  => 'uniasselvi3',
                                    host => 'ftp.intervalor.com.br');
END;
/
COMMIT;


begin
DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl  => 'uniasselvi3',
                                    host => '*');
END;
/


 BEGIN
  DBMS_NETWORK_ACL_ADMIN.DELETE_PRIVILEGE(acl       => 'uniasselvi3',
                                       principal => 'DBAASS',
                                       is_grant  => true,
                                       privilege => 'resolve');
 
  DBMS_NETWORK_ACL_ADMIN.UNASSIGN_ACL(acl  => 'uniasselvi3',
                                    host => 'ftp.intervalor.com.br');
END;
/
COMMIT;

BEGIN
  DBMS_NETWORK_ACL_ADMIN.UNASSIGN_ACL(acl  => 'uniasselvi3',
                                    host => 'ftp.intervalor.com.br');
END;
/
COMMIT;