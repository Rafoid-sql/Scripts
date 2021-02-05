#set -x
#!/bin/ksh
#######################################################
# Autor: Michel Souza - Indyxa                        #
# Email: michel.souza@indyxa.com.br                   #
# Data.: 14/06/2019                                   #
#######################################################

#Conf Backup 
export ORACLE_BASE=/orabin/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0.2/db_1
export PATH=/usr/sbin:$PATH:/sbin:$ORACLE_HOME/bin
export ORACLE_SID=$1
export DIR_BASE=/orabackup/fisico/${ORACLE_SID}
export DIR_LOG=$DIR_BASE/logs
export DIR_BKP=$DIR_BASE/files
export ARQ_LOG=$DIR_LOG/RmanBackupArchive_${ORACLE_SID}_`date '+%d%m%Y_%H%M'`.log
export DIR_SCRIPT=$DIR_BASE/script
export EMAIL=joao.vitor@teiko.com.br
export COPIA_REMOTA=N
export RMAN_USER=teikobkp
export RMAN_PASSWORD=bkpokiet
#Origen do archives
export OR_ARCH=/oraarchive/dbprod

# Variavies Monitoramento
export FAROL_HOME=/usr/local/Teiko/Farol
export FAROL=$FAROL_HOME/farolevent.sh

EVENTO(){
# Funcao que efetua o envio de evento para o monitoramento
  if [ "${ret}" != "0" ]
         then
         STATUS=ERRO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanarch_${ORACLE_SID} --severidade=2 --im=rmanarch_${ORACLE_SID} --mensagem="Erro no Backup Oracle RMAN_ARCHIVE" --anexo=${ARQ_LOG}
		else
         STATUS=SUCESSO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanarch_${ORACLE_SID} --severidade=0 --im=rmanarch_${ORACLE_SID} --mensagem="Sucesso no Backup Oracle RMAN_ARCHIVE"
		fi
        echo  " Fim do backup de archive via rman em ${sid}, com status=${STATUS}..." >> ${ARQ_LOG}
}

EVENTO_COPIA(){
DESCRICAO_MENSAGEM="$1"
SEVERIDADE_MENSAGEM=$2
# Funcao que efetua o envio de evento para o monitoramento
  if [ ${SEVERIDADE_MENSAGEM} != "0" ]
         then
         STATUS=ERRO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanarch_copia_${ORACLE_SID} --severidade=${SEVERIDADE_MENSAGEM} --im=rmanarch_copia_${ORACLE_SID} --mensagem=${DESCRICAO_MENSAGEM}  --anexo=${ARQ_LOG}
		else
         STATUS=SUCESSO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanarch_copia_${ORACLE_SID} --severidade=${SEVERIDADE_MENSAGEM} --im=rmanarch_copia_${ORACLE_SID} --mensagem=${DESCRICAO_MENSAGEM} 
		fi
        echo  " Fim do backup de archive via rman em ${sid}, com status=${STATUS}..." >> ${ARQ_LOG}
}

REMOTO (){
       echo "Inciando copia remota do Backup Rman Archive" >> ${ARQ_LOG}
       /sbin/mount.cifs //192.168.0.2/backup_oracle /mnt/fisico -o username=teiko,password=teiko123
       ret=$?
       if [ "${ret}" != "0" ]
       then
          echo "Erro mount filesystem remoto do Backup" >> ${ARQ_LOG}
          EVENTO_COPIA "Erro mount filesystem remoto do Backup" 2 ${ARQ_LOG}
       else
          find /mnt/fisico/fisico/*.rman -mtime +0 -print -exec rm -f {} \; > /dev/null 2>&1
          find /orabackup/dbprod/rman/files/ -maxdepth 1 -name *.dbf -exec cp -uv {} /mnt/fisico/fisico \; 
          ret=$?
          if [ "${ret}" != "0" ]
          then
             echo " Erro copia remota do Backup Rman Archive" >> ${ARQ_LOG}
             EVENTO_COPIA "Erro copia remota do Backup Rman Archive" 2 ${ARQ_LOG}
          else
             echo " Sucesso copia remota do Backup Rman Archive" >> ${ARQ_LOG}
             EVENTO_COPIA "Sucesso na copia remota do Backup Rman Archive" 0 ${ARQ_LOG}
          fi
          /sbin/umount.cifs /mnt/fisico > /dev/null 2>&1
       fi
}
# rman target / <<EOF 1>> ${ARQ_LOG} 2>> ${ARQ_LOG}
echo "`date` => Inicio do backup rman ..." >> ${ARQ_LOG}
rman target $RMAN_USER/$RMAN_PASSWORD <<EOF 1>> ${ARQ_LOG} 2>> ${ARQ_LOG}
show all;
run {
allocate channel d1 type disk FORMAT '${DIR_BKP}/arch_%d_%s_%p_%t.arc' maxpiecesize 5000M;
sql 'alter system archive log current';
backup as compressed backupset tag 'BackupArchivelogDiario' archivelog like '${OR_ARCH}/%' delete input;
release channel d1;
allocate channel d2 type disk FORMAT '${DIR_BKP}/cf_%d_%s_%p_%t.ctl' maxpiecesize 1000M;
backup as compressed backupset tag 'BackupCurrentControlfile' current controlfile;
release channel d2;
allocate channel d4 type disk FORMAT '${DIR_BKP}/spf_%d_%s_%p_%t.spf' maxpiecesize 1000M;
backup as compressed backupset tag 'BackupSpfile' spfile;
release channel d4;
}
exit
EOF

#Verifica se o backup foi executado com sucesso
if [ -e $ARQ_LOG ]
then

  ERROS=`egrep "ORA-|RMAN-" $ARQ_LOG | egrep -v "RMAN-08138|RMAN-08120" | wc -l`

  if [ "${ERROS}" -gt "0" ]
  then
    ret=1
    echo "--> Finalizou com: Erro na Execucao do Backup Rman Archives - Data: `date`" >> $ARQ_LOG
    EVENTO
  else
    ret=0
    echo "--> Finalizou com: Sucesso na Execucao do Backup Rman Archives - Data: `date`" >> $ARQ_LOG
	EVENTO
    
  fi
else
  ret=1
  EVENTO
fi

if [ ${COPIA_REMOTA} = "S" ]
	then
	REMOTO
fi	

####################
# LIMPEZA DOS LOGS #
####################
find $DIR_LOG/RmanBackupArchive* -mtime +30 -print -exec rm -f {} \; > /dev/null 2>&1
