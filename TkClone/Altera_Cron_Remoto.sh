#!/bin/sh
###############################################################################
# Script           : Altera_Cron_Remoto.sh
# Funcao           : Alterar a Cron do servidor remoto para desativar o backup
#                    dos archives
#
# Data             : 05/08/2015
# Parametros       : N/A
#
# Observacao       : scritp dever ser configurado de acordo com o ambiente do
#                    cliente e deve ser chamado automaticamente pelo CloneDB.
###############################################################################

CLONE_HOME=/usr/local/Teiko/Clone
export CLONE_HOME
ssh oracle@hsd008 "sh $CLONE_HOME/script/tk_altera_cron.sh"
