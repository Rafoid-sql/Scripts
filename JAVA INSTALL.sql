--https://itkbs.wordpress.com/2014/02/15/how-to-install-java-in-oracle-database-ora-29538/

--Instalar JAVA:

--Check:
select comp_name, version, status from dba_registry;

/*
Oracle Enterprise Manager 11.2.0.4.0 VALID
Oracle XML Database 11.2.0.4.0 VALID
Oracle Workspace Manager 11.2.0.4.0 VALID
Oracle Database Catalog Views 11.2.0.4.0 VALID
Oracle Database Packages and Types 11.2.0.4.0 VALID
*/

--Double check:
select distinct owner,name from dba_source where lower(NAME)='dbms_java';
--no rows selected

--Install:
@$ORACLE_HOME/javavm/install/initjvm.sql

--Check again:
select comp_name, version, status from dba_registry;

/*
Oracle Enterprise Manager 11.2.0.4.0 VALID
Oracle XML Database 11.2.0.4.0 VALID
Oracle Workspace Manager 11.2.0.4.0 VALID
Oracle Database Catalog Views 11.2.0.4.0 VALID
Oracle Database Packages and Types 11.2.0.4.0 VALID
JServer JAVA Virtual Machine 11.2.0.4.0 VALID
*/

--Double check again:
select distinct owner,name from dba_source where lower(NAME)='dbms_java';
/*
OWNER                          NAME
------------------------------ ------------------------------
SYS                            DBMS_JAVA
*/