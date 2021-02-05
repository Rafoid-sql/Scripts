#!/bin/bash
###############################################################################
#Script           : TK_Altera_Cron.sh
#Funcao           : Alterar a Cron para desativar o backup dos archives
#
#Data             : 05/08/2015
#Parametros       : N/A
#
#Observacao       : scritp dever ser configurado de acordo com o ambiente do
#                   cliente e deve ser chamado automaticamente pelo CloneDB.
###############################################################################

 CLONE_HOME=/usr/local/Teiko/Clone
 BASE_DIR=$CLONE_HOME/tmp
 ARQ_LOG=$CLONE_HOME/log/tk_altera_cron_`date '+%Y%m%d_%H'`.log
 EXEC_ATUAL=BackupRmanArch.sh
 ORACLE_SID_ORG=cdbprd11
 ArqLogProcesso=$ARQ_LOG
 STATUS=OK
 MON_SERVER=$CLONE_HOME/script/TK_Mon_Server.sh
 export BASE_DIR ORACLE_SID ARQ_LOG  EXEC_ATUAL ORACLE_SID_ORG ArqLogProcesso STATUS MON_SERVER CLONE_HOME

#VERIFICA EXECUCAO DO BACKUP DE ARCHIVES
 ps -ef > /usr/local/Teiko/Clone/tmp/ps.txt
 PS_ARCH=`cat /usr/local/Teiko/Clone/tmp/ps.txt | grep $EXEC_ATUAL`
 while [ -n "$PS_ARCH" ]
 do
         echo [`date '+%X %x'`] " -> BACKUP DE ARCHIVES EM ANDAMENTO" >> /usr/local/Teiko/Clone/tmp/logarch.log
         sleep 120
         echo > $BASE_DIR/ps.txt
         PS_ARCH=`cat /usr/local/Teiko/Clone/tmp/ps.txt | grep $EXEC_ATUAL`
         CONTA_TEMPO = $CONTA_TEMPO + 1;
         if [ $CONTA_TEMPO = 15 ];
         then
                echo [`date '+%X %x'`] " -> BACKUP DE ARCHIVES EXECUTANDO A MAIS DE 30 MINUTOS, ENCERRANDO ROTINA" >> /usr/local/Teiko/Clone/tmp/logarch.log
                exit
         fi
                ps -ef > /usr/local/Teiko/Clone/tmp/ps.txt
 done

#Cria novo crontab sem a atualizacao da base de dados standby
 echo [`date '+%X %x'`] " -> GERANDO CRONTAB TEMPORARIO" >> $ARQ_LOG
  ORACLE_SID=$ORACLE_SID_ORG
  sudo crontab -l > $BASE_DIR/crontab.org
 echo [`date '+%X %x'`] " -> DESATIVANDO BACKUP DE ARCHIVES NA CRON" >> $ARQ_LOG
  sudo crontab -l > $BASE_DIR/crontab2.org
 echo "sed '/$EXEC_ATUAL/s/^/#CLONEDB#/' $BASE_DIR/crontab2.org > $BASE_DIR/crontab2.tmp" > $BASE_DIR/crontab2.sh
   sh $BASE_DIR/crontab2.sh
   sudo crontab $BASE_DIR/crontab2.tmp
