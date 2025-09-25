qatpaadmx0003:qadmp3:/home/oracle>sqlplus / as sysdba

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
alter user ADM_QLAB01 grant connect through OPS$ORACLE;
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
=======
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
alter user ADM_VIEW grant connect through OPS$ORACLE;
>>>>>>> Stashed changes
alter user ADM_ZLAB10 grant connect through  
=======
=======
>>>>>>> Stashed changes
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
alter user ADM_VIEW grant connect through OPS$ORACLE;
alter user ADM_ZLAB10 grant connect through OPS$ORACLE;
>>>>>>> Stashed changes
alter user ADM_QLAB07 grant connect through OPS$ORACLE;


ALTER USER ASHETTY13 REVOKE CONNECT THROUGH OPS$ORACLE;

User altered.



connect [ADM_DLAB01]/
connect [ADM_QLAB02_VIEW]/
connect [ADM]/
connect [ADM_ZLAB10]/
connect [ADM_QLAB07]/


SQL> connect [ADM_QLAB01]/
Connected.
SQL> show user
USER is "ADM_QLAB01"
SQL>


<<<<<<< Updated upstream
sqlplus [SCMSA_ABC]/@qadp06_aws
sqlplus [SCMSA_HIST]/@qids06_aws
sqlplus [SCMSA_ABC]/@qsaa06_aws
sqlplus [SCMSA_ABC]/@qsaaup06_aws
=======








<<<<<<< Updated upstream
<<<<<<< Updated upstream
sqlplus [VSTAPPO]/@qadp06_aws
sqlplus [SPRINT_COMM]/@qids06_aws
=======
sqlplus [SCMSA_LAND]/@qadp06_aws
sqlplus [DCS_HIST]/@qids06_aws
>>>>>>> Stashed changes
=======
sqlplus [SCMSA_LAND]/@qadp06_aws
sqlplus [DCS_HIST]/@qids06_aws
>>>>>>> Stashed changes
sqlplus [SCMSA_ABC]/@qsaa06_aws
sqlplus [SCMSA_ABC]/@qsaaup06_aws






sqlplus [DCS_HIST]/@qids06_aws

sqlplus [DVARI_HIST]/@qids06_aws

sqlplus [SCMSA_HIST]/@qids06_aws


SQL> show errors
Errors for PACKAGE BODY SCMSA_HIST.ECS_SUB_ACTIVITY_PKG:

LINE/COL ERROR
-------- -----------------------------------------------------------------
2090/3   PL/SQL: SQL Statement ignored
2090/25  PL/SQL: ORA-00942: table or view does not exist
2172/4   PL/SQL: SQL Statement ignored
2179/14  PL/SQL: ORA-00942: table or view does not exist
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
