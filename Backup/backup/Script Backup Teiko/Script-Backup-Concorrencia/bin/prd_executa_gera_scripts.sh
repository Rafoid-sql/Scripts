#!/bin/bash
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_SID=prd; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH; export PATH
sqlplus -s transfer_arc/transfer_arc @/home/oracle/scripts/bin/prd_gera_scripts_transfer_archives.sql


