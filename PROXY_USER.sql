qatpaadmx0003:qadmp3:/home/oracle>sqlplus / as sysdba

alter user ADM_QLAB01 grant connect through OPS$ORACLE;
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
alter user ADM_VIEW grant connect through OPS$ORACLE;
alter user ADM_ZLAB10 grant connect through  
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
alter user ADM_VIEW grant connect through OPS$ORACLE;
alter user ADM_ZLAB10 grant connect through OPS$ORACLE;
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

sqlplus [SCH_IOT]/@qadp06_aws
sqlplus [SCMSA_HIST]/@qids06_aws
sqlplus [SCMSA_ABC]/@qsaa06_aws
sqlplus [SCMSA_ABC]/@qsaaup06_aws

sqlplus [SCMSA_LAND]/@qadp06_aws
sqlplus [SCMSA_HIST]/@qids06_aws
sqlplus [SCMSA_ABC]/@qsaa06_aws
sqlplus [SCMSA_ABC]/@qsaaup06_aws


sqlplus [DCS_HIST]/@qids06_aws
sqlplus [DVARI_HIST]/@qids06_aws
sqlplus [SCMSA_HIST]/@qids06_aws

