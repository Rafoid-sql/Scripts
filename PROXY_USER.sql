qatpaadmx0003:qadmp3:/home/oracle>sqlplus / as sysdba

alter user ADM_QLAB01 grant connect through OPS$ORACLE;
alter user ADM_QLAB02_VIEW grant connect through OPS$ORACLE;
alter user ADM_ZLAB10 grant connect through OPS$ORACLE;
alter user ADM_QLAB07 grant connect through OPS$ORACLE;

User altered.



connect [ADM_QLAB01]/
connect [ADM]/
connect [ADM_ZLAB10]/
connect [ADM_QLAB07]/


SQL> connect [ADM_QLAB01]/
Connected.
SQL> show user
USER is "ADM_QLAB01"
SQL>


sqlplus [VSTAPPO]/@qadp06_aws
sqlplus [SPRINT_COMM]/@qids06_aws
sqlplus [SCMSA_ABC]/@qsaa06_aws
sqlplus [SCMSA_ABC]/@qsaaup06_aws