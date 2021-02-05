#!/bin/bash

# DEFINE VARIAVEIS DE AMBIENTE DO GRID ########################################
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_HOSTNAME=dboraprod; export ORACLE_HOSTNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=/u01/app/oracle/product/grid/; export ORACLE_HOME
ORACLE_SID=+ASM; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
PATH=/usr/sbin:$PATH; export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH

# EXECUTA SCRIPT DE TRANSFERENCIA DOS ARCHIVES DO PRIMARIO PARA STANDBY #######
chmod 765 /home/oracle/scripts/bin/PRD_TRANSFERE_ARCHIVE_TO_STANDBY.sh
/home/oracle/scripts/bin/PRD_TRANSFERE_ARCHIVE_TO_STANDBY.sh


# DEFINE VARIAVEIS DE AMBIENTE DO DATABASE #####################################
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_SID=prd; export ORACLE_SID
ORACLE_TERM=xterm; export ORACLE_TERM
PATH=$ORACLE_HOME/bin:/usr/sbin:$PATH; export PATH

# EXECUTA SCRIPT PARA GRAVAR OS LOGS DOS ARCHIVES TRANSFERIDOS ################
sqlplus -s transfer_arc/transfer_arc @/home/oracle/scripts/bin/PRD_GRAVA_LOG_ARCHIVE_TRANSFERIDO.sql

# RENOMEIA OS ARQUIVOS EXECUTADOS #############################################
DATEHOUR=`date '+%d-%m-%Y_%H:%M:%S'`
mv /home/oracle/scripts/bin/PRD_TRANSFERE_ARCHIVE_TO_STANDBY.sh /home/oracle/scripts/bin/logs_standby/PRD_TRANSFERE_ARCHIVE_TO_STANDBY_$DATEHOUR.sh
mv /home/oracle/scripts/bin/PRD_GRAVA_LOG_ARCHIVE_TRANSFERIDO.sql /home/oracle/scripts/bin/logs_standby/PRD_GRAVA_LOG_ARCHIVE_TRANSFERIDO_$DATEHOUR.sql

