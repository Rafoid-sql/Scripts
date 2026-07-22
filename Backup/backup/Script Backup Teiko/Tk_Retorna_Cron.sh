#!/bin/bash
###############################################################################
# Script           : TK_Retorna_Cron.sh
# Funcao           : Retorna as configurações da Cron ativando os backups de
#                    Archives
# Data             : 05/08/2015
# Parametros       : N/A
#
# Observacao       : scritp dever ser configurado de acordo com o ambiente do
#                    cliente e deve ser chamado automaticamente pelo CloneDB.
###############################################################################

CLONE_HOME=/usr/local/Teiko/Clone
BASE_DIR=$CLONE_HOME/tmp
ARQ_LOG=$CLONE_HOME/log/tk_retorna_cron_`date '+%Y%m%d_%H'`.log
EXEC_ATUAL_STB=TkAtualizaStandby.sh
ORACLE_SID_ORG=tasy
ArqLogProcesso=$ARQ_LOG
STATUS=OK
ORACLE_SID=$ORACLE_SID_ORG
tk_mon_server='sh TK_Mon_Server.sh'
export CLONE_HOME BASE_DIR ORACLE_SID ARQ_LOG EXEC_ATUAL_STB ORACLE_SID_ORG ArqLogProcesso STATUS

# Para o servi▒o de monitoramente entre o Target e Auliliary
#killall $tk_mon_server

# Restaura a configura▒▒o original da Cron
echo [`date '+%X %x'`] " -> RESTAURANDO CONFIGURACOES ANTERIORES CRONTAB" >> $ARQ_LOG
crontab $BASE_DIR/crontab.org
rm -f $BASE_DIR/crontab.org
rm -f $BASE_DIR/crontab.tmp
rm -f $BASE_DIR/crontab2.org
rm -f $BASE_DIR/crontab2.tmp
