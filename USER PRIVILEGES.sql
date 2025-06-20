-- RUN BEFORE ANY OTHER QUERY:
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
SET LINES 280 PAGESIZE 1000 LONG 15000 ECHO ON TIME ON TIMING ON TRIM ON TRIMSPOOL ON UNDERLINE =
=========================================================================================================================================
--Create grant list for user:
SELECT 'GRANT SELECT,INSERT,UPDATE,DELETE ON '||'"'||OWNER||'"'||'.'||'"'||OBJECT_NAME||'"'|| ' TO APUPPAL1;' FROM DBA_OBJECTS WHERE OBJECT_TYPE IN ('TABLE') AND OWNER='ADM';
<<<<<<< Updated upstream
SELECT 'GRANT SELECT ON '||'"'||OWNER||'"'||'.'||'"'||OBJECT_NAME||'"'|| ' TO ABALAJI1;' FROM DBA_OBJECTS WHERE OBJECT_TYPE IN ('TABLE','VIEW') AND OWNER='ADM';
=======
SELECT 'GRANT SELECT ON '||'"'||OWNER||'"'||'.'||'"'||OBJECT_NAME||'"'|| ' TO ADM_RO;' FROM DBA_OBJECTS WHERE OBJECT_TYPE IN ('TABLE') AND OWNER='ADM';
>>>>>>> Stashed changes
SELECT 'GRANT EXECUTE ON '||'"'||OWNER||'"'||'.'||'"'||OBJECT_NAME||'"'|| ' TO CDES1_EXECUTE_PROCEDURES;' FROM DBA_OBJECTS WHERE OBJECT_TYPE IN ('PROCEDURE') AND OWNER='CDES1';
=========================================================================================================================================
--Get grants from user to apply to another:
SELECT * FROM (
SELECT 'GRANT '||PRIVILEGE||' TO '||GRANTEE||';' FROM DBA_SYS_PRIVS WHERE GRANTEE IN UPPER('&&user')
UNION ALL
SELECT 'GRANT '||PRIVILEGE||' ON '||GRANTOR||'.'||TABLE_NAME||' TO '||GRANTEE||';' FROM DBA_TAB_PRIVS WHERE GRANTEE IN UPPER('&&user')
UNION ALL
SELECT 'GRANT '||GRANTED_ROLE||' TO '||GRANTEE||';' FROM DBA_ROLE_PRIVS WHERE GRANTEE IN UPPER('&&user')
ORDER BY 1);

UNDEFINE user;
=========================================================================================================================================
--Count user privileges
SELECT PRIVILEGE,COUNT(PRIVILEGE) QTY FROM DBA_SYS_PRIVS WHERE GRANTEE='&&USER' GROUP BY PRIVILEGE
UNION ALL
SELECT PRIVILEGE,COUNT(PRIVILEGE) QTY FROM DBA_TAB_PRIVS WHERE GRANTEE='&&USER' GROUP BY PRIVILEGE
UNION ALL
SELECT GRANTED_ROLE as PRIVILEGE,COUNT(GRANTED_ROLE) QTY FROM DBA_ROLE_PRIVS WHERE GRANTEE='&&USER' GROUP BY GRANTED_ROLE;

UNDEFINE user;
=========================================================================================================================================
--Get user privileges:
COL TABLE FOR A15
COL PRIVILEGE FOR A30
COL GRANTOR FOR A25
COL OBJECT FOR A30
COL GRANTEE FOR A30
SELECT * FROM (
SELECT 'SYS_PRIVS' AS "TABLE",PRIVILEGE,NULL "GRANTOR", NULL "OBJECT",GRANTEE FROM DBA_SYS_PRIVS WHERE GRANTEE IN UPPER('&&user')
UNION ALL
SELECT 'TAB_PRIVS' AS "TABLE",PRIVILEGE,GRANTOR,TABLE_NAME "OBJECT",GRANTEE FROM DBA_TAB_PRIVS WHERE GRANTEE IN UPPER('&&user')
UNION ALL
SELECT 'ROLE_PRIVS' AS "TABLE",GRANTED_ROLE "PRIVILEGE",NULL "GRANTOR", NULL "OBJECT",GRANTEE FROM DBA_ROLE_PRIVS WHERE GRANTEE IN UPPER('&&user')
ORDER BY 3,1);

UNDEFINE user;
=========================================================================================================================================
--Get user privileges II:
COL TABLE FOR A15
COL PRIVILEGE FOR A30
COL OBJECT FOR A60
COL GRANTEE FOR A10
SELECT * FROM (
SELECT GRANTEE, PRIVILEGE, '--' "OBJECT" FROM DBA_SYS_PRIVS WHERE GRANTEE IN (SELECT USERNAME FROM DBA_USERS WHERE PROFILE='APPUSER_PROFILE')
UNION ALL
SELECT GRANTEE, PRIVILEGE,GRANTOR||'.'||TABLE_NAME "OBJECT" FROM DBA_TAB_PRIVS WHERE GRANTEE IN (SELECT USERNAME FROM DBA_USERS WHERE PROFILE='APPUSER_PROFILE')
UNION ALL
SELECT GRANTEE, GRANTED_ROLE "PRIVILEGE", '--' "OBJECT" FROM DBA_ROLE_PRIVS WHERE GRANTEE IN (SELECT USERNAME FROM DBA_USERS WHERE PROFILE='APPUSER_PROFILE')
ORDER BY 1,3,2);
=========================================================================================================================================
--Get user privileges by object:
COL USERNAME FOR A20
COL PRIVILEGE FOR A30
COL OWNER FOR A15
COL TABLENAME FOR A50
COL COLUMN_NAME FOR A25
COL ADMIN_OPTION FOR A15
SELECT A.*FROM (
	SELECT GRANTEE USERNAME, GRANTED_ROLE PRIVILEGE, '--' OWNER, '--' TABLENAME, '--' COLUMN_NAME,  ADMIN_OPTION ADMIN_OPTION,  'ROLE' ACCESS_TYPE
	FROM DBA_ROLE_PRIVS RP JOIN DBA_ROLES R ON RP.GRANTED_ROLE = R.ROLE
	WHERE GRANTEE IN ('&&USER')
UNION
	SELECT GRANTEE USERNAME, PRIVILEGE PRIVILEGE, '--' OWNER, '--' TABLENAME, '--' COLUMN_NAME,  ADMIN_OPTION ADMIN_OPTION,  'SYSTEM' ACCESS_TYPE
	FROM DBA_SYS_PRIVS
	WHERE GRANTEE IN ('&&USER')
UNION
	SELECT GRANTEE USERNAME, PRIVILEGE PRIVILEGE, OWNER OWNER, TABLE_NAME TABLENAME, '--' COLUMN_NAME, GRANTABLE ADMIN_OPTION, 'TABLE' ACCESS_TYPE
	FROM DBA_TAB_PRIVS
	WHERE GRANTEE IN ('&&USER')
UNION
	SELECT DP.GRANTEE USERNAME, PRIVILEGE PRIVILEGE, OWNER OWNER, TABLE_NAME TABLENAME, COLUMN_NAME COLUMN_NAME, '--' ADMIN_OPTION, 'ROLE' ACCESS_TYPE
	FROM ROLE_TAB_PRIVS RP, DBA_ROLE_PRIVS DP
	WHERE RP.ROLE = DP.GRANTED_ROLE AND DP.GRANTEE IN ('&&USER')
UNION
	SELECT GRANTEE USERNAME, PRIVILEGE PRIVILEGE, GRANTABLE ADMIN_OPTION, OWNER OWNER, TABLE_NAME TABLENAME, COLUMN_NAME COLUMN_NAME, 'COLUMN' ACCESS_TYPE
	FROM DBA_COL_PRIVS
	WHERE GRANTEE IN ('&&USER')) A
ORDER BY USERNAME, A.TABLENAME,
	CASE
		WHEN A.ACCESS_TYPE = 'SYSTEM' THEN 1
		WHEN A.ACCESS_TYPE = 'TABLE' THEN 2
		WHEN A.ACCESS_TYPE = 'COLUMN' THEN 3
		WHEN A.ACCESS_TYPE = 'ROLE' THEN 4
		ELSE 5
	END,
	CASE
		WHEN A.PRIVILEGE IN ('EXECUTE') THEN 1
		WHEN A.PRIVILEGE IN ('SELECT', 'INSERT', 'DELETE') THEN 3
		ELSE 2
	END,
	A.COLUMN_NAME, A.PRIVILEGE;

UNDEFINE USER;
=========================================================================================================================================
--Count Grants from user:
SELECT SUM(GRANTED) AS PRIVS FROM (
SELECT count(GRANTEE) AS GRANTED FROM DBA_SYS_PRIVS WHERE GRANTEE IN UPPER('ssakthi2')
UNION ALL
SELECT count(GRANTEE) AS GRANTED FROM DBA_TAB_PRIVS WHERE GRANTEE IN UPPER('ssakthi2')
UNION ALL
SELECT count(GRANTEE) AS GRANTED FROM DBA_ROLE_PRIVS WHERE GRANTEE IN UPPER('ssakthi2')
GROUP BY GRANTEE
ORDER BY 1);
=========================================================================================================================================
--Get grants from user:
COL OBJ_OWNER HEADING 'OBJECT|OWNER' FOR A20
COL OBJ_NAME HEADING 'OBJECT|NAME' FOR A40
COL GRANT_SOURCES HEADING 'GRANT|SOURCES' FOR A30
COL USERNAME HEADING 'USER|ACCOUNT' FOR A20
COL PRIVILEGE HEADING 'PRIVILEGE|TYPE' FOR A20
COL ADMIN_OR_GRANT_OPT HEADING 'ADMIN|OPT' FOR A5
COL HIERARCHY_OPT HEADING 'HIER|OPT' FOR A5
SELECT PRIVILEGE, OBJ_OWNER, OBJ_NAME, USERNAME,
    LISTAGG(GRANT_TARGET, ',') WITHIN GROUP (ORDER BY GRANT_TARGET) AS GRANT_SOURCES, -- LISTS THE SOURCES OF THE PERMISSION
    MAX(ADMIN_OR_GRANT_OPT) AS ADMIN_OR_GRANT_OPT, -- MAX ACTS AS A BOOLEAN OR BY PICKING 'YES' OVER 'NO'
    MAX(HIERARCHY_OPT) AS HIERARCHY_OPT -- MAX ACTS AS A BOOLEAN OR BY PICKING 'YES' OVER 'NO'
FROM (
-- GETS ALL ROLES A USER HAS, EVEN INHERITED ONES
    WITH ALL_ROLES_FOR_USER AS (SELECT DISTINCT CONNECT_BY_ROOT GRANTEE AS GRANTED_USER, GRANTED_ROLE FROM DBA_ROLE_PRIVS CONNECT BY GRANTEE = PRIOR GRANTED_ROLE)
    SELECT PRIVILEGE,OBJ_OWNER,OBJ_NAME,USERNAME,REPLACE(GRANT_TARGET, USERNAME, 'DIRECT TO USER') AS GRANT_TARGET,ADMIN_OR_GRANT_OPT,HIERARCHY_OPT
    FROM (
-- SYSTEM PRIVILEGES GRANTED DIRECTLY TO USERS
        SELECT PRIVILEGE, NULL AS OBJ_OWNER, NULL AS OBJ_NAME, GRANTEE AS USERNAME, GRANTEE AS GRANT_TARGET, ADMIN_OPTION AS ADMIN_OR_GRANT_OPT, NULL AS HIERARCHY_OPT FROM DBA_SYS_PRIVS WHERE GRANTEE IN (SELECT USERNAME FROM DBA_USERS)
        UNION ALL
-- SYSTEM PRIVILEGES GRANTED USERS THROUGH ROLES
        SELECT PRIVILEGE, NULL AS OBJ_OWNER, NULL AS OBJ_NAME, ALL_ROLES_FOR_USER.GRANTED_USER AS USERNAME, GRANTEE AS GRANT_TARGET, ADMIN_OPTION AS ADMIN_OR_GRANT_OPT, NULL AS HIERARCHY_OPT FROM DBA_SYS_PRIVS JOIN ALL_ROLES_FOR_USER ON ALL_ROLES_FOR_USER.GRANTED_ROLE = DBA_SYS_PRIVS.GRANTEE
        UNION ALL
-- OBJECT PRIVILEGES GRANTED DIRECTLY TO USERS
        SELECT PRIVILEGE, OWNER AS OBJ_OWNER, TABLE_NAME AS OBJ_NAME, GRANTEE AS USERNAME, GRANTEE AS GRANT_TARGET, GRANTABLE, HIERARCHY FROM DBA_TAB_PRIVS WHERE GRANTEE IN (SELECT USERNAME FROM DBA_USERS)
        UNION ALL
-- OBJECT PRIVILEGES GRANTED USERS THROUGH ROLES
        SELECT PRIVILEGE, OWNER AS OBJ_OWNER, TABLE_NAME AS OBJ_NAME, ALL_ROLES_FOR_USER.GRANTED_USER AS USERNAME, ALL_ROLES_FOR_USER.GRANTED_ROLE AS GRANT_TARGET, GRANTABLE, HIERARCHY FROM DBA_TAB_PRIVS JOIN ALL_ROLES_FOR_USER ON ALL_ROLES_FOR_USER.GRANTED_ROLE = DBA_TAB_PRIVS.GRANTEE
    ) ALL_USER_PRIVS
-- ADJUST YOUR FILTER HERE
    WHERE USERNAME = '&USER'
) DISTINCT_USER_PRIVS
GROUP BY PRIVILEGE,OBJ_OWNER,OBJ_NAME,USERNAME;

UNDEFINE user;
=========================================================================================================================================
-- Get instance/host name and current sysdate:
SELECT INSTANCE_NAME, HOST_NAME, TO_CHAR(SYSDATE,'DD-MM-YY HH24:MI:SS AM') CURRENT_TIME FROM GV$INSTANCE;

COL NAME FOR A20
SELECT NAME, TO_CHAR(SYSDATE,'DD-MM-YY HH24:MI:SS AM') CURRENT_TIME FROM V$DATABASE, DUAL;
=========================================================================================================================================
--Get list of privileges from user:
COL "PRIVILEGE_TYPE" FOR A15
COL GRANTEE FOR A15
COL GRANTOR FOR A15
COL OWNER FOR A20
COL OBJ_NAME FOR A40
COL PRIVILEGE FOR A30
SELECT 'SYS PRIVS' AS "PRIVILEGE_TYPE", GRANTEE, '' OWNER, '' OBJ_NAME, PRIVILEGE FROM DBA_SYS_PRIVS WHERE GRANTEE IN ('DBSNMP')
UNION ALL
SELECT 'ROLE' AS "PRIVILEGE_TYPE", GRANTEE, '' OWNER, '' OBJ_NAME, GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE IN ('DBSNMP')
UNION ALL
SELECT 'OBJECT' AS "PRIVILEGE_TYPE", GRANTEE, OWNER, TABLE_NAME AS OBJ_NAME, PRIVILEGE FROM DBA_TAB_PRIVS WHERE GRANTEE IN ('DBSNMP');

SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE IN ('SVC_PRD_0225123_DSA');
=========================================================================================================================================
SELECT 'GRANT '||PRIVILEGE||' ON '||GRANTOR||'.'||TABLE_NAME||' TO '||GRANTEE||';' FROM DBA_TAB_PRIVS
WHERE GRANTEE like ('SAG')
AND GRANTOR = ('SYS');

=========================================================================================================================================
-- List privileges, including roles, for my_user
SELECT GRANTEE, PRIVILEGE AS PRIVILEGE_ROLE, NULL AS OWNER, ADMIN_OPTION AS PRIVILEGE, NULL AS GRANTABLE
FROM DBA_SYS_PRIVS WHERE GRANTEE = 'SVC_PRD_EDGE'
UNION ALL
SELECT r.GRANTEE, r.GRANTED_ROLE AS PRIVILEGE_ROLE, p.OWNER, PRIVILEGE, p.GRANTABLE
FROM DBA_ROLE_PRIVS r LEFT JOIN ROLE_TAB_PRIVS p ON p.ROLE = r.GRANTED_ROLE
WHERE r.GRANTEE = 'SVC_PRD_EDGE';
group by PRIVILEGE_ROLE

select 'GRANT SELECT,UPDATE ON '||OWNER||''.''||TABLE_NAME||' TO CVEMULA1;' from dba_tables where owner='LLEE50';

set lines 300 pagesize 1000
SELECT 'GRANT SELECT,UPDATE ON '||OWNER||'.'||TABLE_NAME||' TO CVEMULA1;' from dba_tables where owner='LLEE50';

=========================================================================================================================================
SET LINES 200 PAGES 999999 TRIMS ON ECHO OFF VERIFY OFF FEEDBACK OFF TRIM ON
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
COL HOST_NAME FOR A20
COL TEXT FOR A150
COL NAME FOR A30
COL GRANTEE FOR A9 HEADING "GRANTEE"
COL USERNAME FOR A30 HEADING "USER"
COL DEFAULT_TABLESPACE FOR A24 HEADING "DEFAULT"
COL TEMPORARY_TABLESPACE FOR A16 HEADING "TEMP"
COL CREATED FOR A24 HEADING "CREATED"
COL PRIVILEGE FOR A30 HEADING "PRIVILEGE"
COL GRANTED_ROLE FOR A30 HEADING "ROLE"
COL DEFAULT_ROLE FOR A5 HEADING "DEFAULT"
COL "OBJECT" FOR A40 HEADING "OBJECT"
COL GRANTOR FOR A10 HEADING "GRANTOR"
COL PRIVILEGE FOR A30 HEADING "PRIVILEGE"
COL USER_PRIV FOR A45

--SET ESCCHAR $
--SPOOL &&1._USER_INFO.LOG

SET ECHO ON FEEDBACK ON VERIFY ON

SELECT INSTANCE_NAME,VERSION, HOST_NAME, SYSTIMESTAMP FROM V$INSTANCE;

-- USER ACCOUNT STATUS
SELECT USERNAME, ACCOUNT_STATUS, DEFAULT_TABLESPACE, TEMPORARY_TABLESPACE, CREATED FROM DBA_USERS WHERE USERNAME = UPPER('&1');

-- ROLES
SELECT GRANTEE, GRANTED_ROLE, DEFAULT_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE = UPPER('&1') ORDER BY GRANTED_ROLE;

-- SYSTEM PRIVILEGES
SELECT GRANTEE, PRIVILEGE FROM DBA_SYS_PRIVS WHERE GRANTEE = UPPER('&1') ORDER BY PRIVILEGE;


-- OBJECT PRIVILEGES
SELECT GRANTEE, PRIVILEGE, OWNER|| '.'|| TABLE_NAME AS "OBJECT" FROM DBA_TAB_PRIVS WHERE GRANTEE = UPPER('&1') 
ORDER BY OWNER || '.' || TABLE_NAME;

-- ROLE PRIVILEGES
SELECT GRANTEE, PRIVILEGE, OWNER|| '.'|| TABLE_NAME AS "OBJECT" FROM DBA_TAB_PRIVS WHERE GRANTEE IN (SELECT GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE = UPPER('&1')) 
ORDER BY GRANTEE;

--SPOOL OFF
CLEAR COLUMN
set echo off

--PROMPT
--PROMPT ***************************************************
--PROMPT
--PROMPT Output saved at &&1._user_info.log
--PROMPT

--HOST uuencode ${&1}_user_info.log ${&1}_user_info.log | mailx -s "user" rafael.oliveira@t-mobile.com

UNDEFINE 1;

=========================================================================================================================================
PROMPT ##############################################################################################################
prompt -- Version 20250304 ---List all privileges and permissions given to a user
/*
RUN THE FOLLOWING TO UPDATE IT

host rm up.sql
host vi up.sql

rm /oracle/g01/admin/common/sqltoolkit/up.sql
vi /oracle/g01/admin/common/sqltoolkit/up.sql

host rm /oracle/g01/admin/common/sqltoolkit/up.sql.old
host mv /oracle/g01/admin/common/sqltoolkit/up.sql /oracle/g01/admin/common/sqltoolkit/up.sql.old
host vi /oracle/g01/admin/common/sqltoolkit/up.sql


*/
@afor

alter session set nls_date_format = 'DD-Mon-YYYY HH24:MI:SS';

accept enter_username prompt 'Add the user name: '


SET LINE 300 pages 500 verify off
select
  lpad(' ', 2*level) || granted_role "User, his roles and privileges"
from
  (
  /* THE USERS */
    select
      null     grantee,
      username granted_role
    from
      dba_users
    where
      username like upper('&enter_username')
  /* THE ROLES TO ROLES RELATIONS */
  union
    select
      grantee,
      granted_role
    from
      dba_role_privs
  /* THE ROLES TO PRIVILEGE RELATIONS */
  union
    select
      grantee,
      privilege
    from
      dba_sys_privs
  )
start with grantee is null
connect by grantee = prior granted_role;




prompt #############################################################################################################################################################################
prompt #SYS PRIVS BY USER:

col PRIVILEGE for a40

SELECT * FROM dba_sys_privs WHERE GRANTEE like upper('&enter_username') ORDER BY GRANTEE, PRIVILEGE;


prompt ############################################################################################################################################################################
prompt #OBJECTS PRIVS BY USER:

COL GRANTEE FOR A25
COL OWNER  FOR A15
COL GRANTOR  FOR A15
COL TABLE_NAME FOR A30
COL PRIVILEGE FOR A15
SELECT * FROM DBA_TAB_PRIVS WHERE GRANTEE like upper('&enter_username') ORDER BY GRANTEE, OWNER,TABLE_NAME, PRIVILEGE;


prompt #############################################################################################################################################################################
prompt ###ROLE PRIVS BY USER:


SELECT *
FROM dba_role_privs where
GRANTEE like upper('&enter_username') ORDER BY GRANTEE, GRANTED_ROLE;

prompt -- Do you want to see the list of permissions on all objects? Press ENTER If YES
set pause     on
set pagesize  30
set pause     'Press ENTER for more rows... '

prompt ##############################################################################################################################################################################
prompt #OBJECTS PRIVS BY ROLE:



COL GRANTEE FOR A25
COL OWNER  FOR A15
COL GRANTOR  FOR A15
COL TABLE_NAME FOR A30
COL PRIVILEGE FOR A15
SELECT * FROM DBA_TAB_PRIVS WHERE GRANTEE IN (SELECT GRANTED_ROLE
FROM dba_role_privs where
GRANTEE like upper('&enter_username')) ORDER BY GRANTEE, OWNER, TABLE_NAME, PRIVILEGE;