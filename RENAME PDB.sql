SQLPLUS / AS SYSDBA <<EOF
ALTER PLUGGABLE DATABASE TOTVS CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE TOTVS OPEN RESTRICTED;
ALTER SESSION SET CONTAINER=TOTVS;
ALTER PLUGGABLE DATABASE RENAME GLOBAL_NAME TO TOTVSHML;
ALTER PLUGGABLE DATABASE TOTVSHML CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE TOTVSHML OPEN;
EOF