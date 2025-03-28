qatpaadmx0003:qadmp3:/home/oracle>sqlplus / as sysdba

alter user ADM_QLAB01 grant connect through OPS$ORACLE;
alter user ADM grant connect through OPS$ORACLE;
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













