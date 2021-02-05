#!/bin/bash
chmod 765 /home/oracle/scripts/bin/PRD_REMOVE_ARCHIVES.sh

# DEFINE VARIAVEIS DE AMBIENTE DO GRID ########################################
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_HOSTNAME=dboraprod; export ORACLE_HOSTNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=/u01/app/oracle/product/11.2.0/grid/; export ORACLE_HOME
ORACLE_SID=+ASM; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
PATH=/usr/sbin:$PATH; export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH
/home/oracle/scripts/bin/PRD_REMOVE_ARCHIVES.sh
rm /home/oracle/scripts/bin/PRD_REMOVE_ARCHIVES.sh
