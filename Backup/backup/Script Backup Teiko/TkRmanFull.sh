#set -x
#!/bin/ksh
#######################################################
# Autor: Joao Vitor - Teiko                           #
# Email: joao.vitor@teiko.com.br                      #
# Data.: 10/07/2014                                   #
#######################################################

#Conf Backup 
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.1.0/dbhome_1
export PATH=/usr/sbin:$PATH:/sbin:$ORACLE_HOME/bin
export ORACLE_SID=$1
export DIR_BASE=/u03/backup/${ORACLE_SID}/fisico/
export DIR_LOG=$DIR_BASE/logs
export DIR_BKP=$DIR_BASE/files
export ARQ_LOG=$DIR_LOG/RmanBackupFull_${ORACLE_SID}_`date '+%d%m%Y_%H%M'`.log
export DIR_SCRIPT=$ORACLE_BASE/Teiko/script/backup
export EMAIL=joao.vitor@teiko.com.br
export RET_BKP=3
export COPIA_REMOTA=N
export RMAN_USER=teikobkp
export RMAN_PASSWORD=bkpokiet
#Origen do archives
export OR_ARCH=/u03/archive/prd2132
# export OR_STANDBY=/oraarchive/dbprod
# change archivelog like '${OR_STANDBY}/%' uncatalog;

# Variavies Monitoramento
export FAROL_HOME=/usr/local/Teiko/Farol
export FAROL=$FAROL_HOME/farolevent.sh

EVENTO(){
# Funcao que efetua o envio de evento para o monitoramento
  if [ "${ret}" != "0" ]
         then
         STATUS=ERRO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanfull_${ORACLE_SID} --severidade=2 --im=rmanfull_${ORACLE_SID} --mensagem="Erro no Backup Oracle RMAN_FULL" --anexo=${ARQ_LOG}
		else
         STATUS=SUCESSO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanfull_${ORACLE_SID} --severidade=0 --im=rmanfull_${ORACLE_SID} --mensagem="Sucesso no Backup Oracle RMAN_FULL"
		fi
        echo  " Fim do backup full via rman em ${sid}, com status=${STATUS}..." >> ${ARQ_LOG}
}

EVENTO_COPIA(){
DESCRICAO_MENSAGEM="$1"
SEVERIDADE_MENSAGEM=$2
# Funcao que efetua o envio de evento para o monitoramento
  if [ ${SEVERIDADE_MENSAGEM} != "0" ]
         then
         STATUS=ERRO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanfull_copia_${ORACLE_SID} --severidade=${SEVERIDADE_MENSAGEM} --im=rmanfull_copia_${ORACLE_SID} --mensagem=${DESCRICAO_MENSAGEM} --anexo=${ARQ_LOG}
		else
         STATUS=SUCESSO
         sh ${FAROL} --alvo=${ORACLE_SID} --aplicacao=Backup_Teiko --objeto=rmanfull_copia_${ORACLE_SID} --severidade=${SEVERIDADE_MENSAGEM} --im=rmanfull_copia_${ORACLE_SID} --mensagem=${DESCRICAO_MENSAGEM}
		fi
        echo  " Fim do backup full via rman em ${sid}, com status=${STATUS}..." >> ${ARQ_LOG}
}

REMOTO (){
	ls /mnt/filesora/fisico/
	ret=$?
	if [ "${ret}" != "0" ]
	then
		echo " Erro copia remota do Backup Rman DataPump" >> ${ARQ_LOG}
		EVENTO_COPIA "Erro copia remota do Backup Rman DataPump" 2 ${ARQ_LOG}
	else
		find ${DIR_BKP}/files/*.dbf -mtime +7 -print -exec rm -f {} \; > /dev/null 2>&1
		find ${DIR_BKP}/files/*.ctl -mtime +7 -print -exec rm -f {} \; > /dev/null 2>&1
		cp -uv ${DIR_BKP}/files/*.ctl /mnt/filesora/fisico/
		cp -uv ${DIR_BKP}/files/*.dbf /mnt/filesora/fisico/
		ret=$?
		if [ "${ret}" != "0" ]
		then
			echo " Erro copia remota do Backup Rman DataPump" >> ${ARQ_LOG}
			EVENTO_COPIA "Erro copia remota do Backup Rman DataPump" 2 ${ARQ_LOG}
		else
			echo " Sucesso copia remota do Backup Rman DataPump" >> ${ARQ_LOG}
			EVENTO_COPIA "Sucesso na copia remota do Backup Rman DataPump" 0 ${ARQ_LOG}
		fi
	fi  

}

#rman target / <<EOF 1>> ${ARQ_LOG} 2>> ${ARQ_LOG}

echo "`date` => Inicio do backup rman ..." >> $ARQ_LOG
rman target $RMAN_USER/$RMAN_PASSWORD <<EOF 1>> ${ARQ_LOG} 2>> ${ARQ_LOG}
show all;
run {
CONFIGURE RETENTION POLICY TO REDUNDANCY ${RET_BKP};
allocate channel d1 type disk FORMAT '${DIR_BKP}/df_%d_%s_%p_%t.dbf' maxpiecesize 10000M;
backup as compressed backupset tag 'BackupDatabaseFullDiario' database;
release channel d1;
sql 'alter system archive log current';
allocate channel d3 type disk FORMAT '${DIR_BKP}/arch_%d_%s_%p_%t.arc' maxpiecesize 5000M;
backup as compressed backupset tag 'BackupArchivelogDiario' archivelog like '${OR_ARCH}/%' delete input;
release channel d3;
allocate channel d2 type disk FORMAT '${DIR_BKP}/cf_%d_%s_%p_%t.ctl' maxpiecesize 1000M;
backup as compressed backupset tag 'BackupCurrentControlfile' current controlfile;
release channel d2;
crosscheck copy of controlfile;
delete noprompt obsolete;
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
    echo "--> Finalizou com: Erro na Execucao do Backup Rman - Data: `date`" >> $ARQ_LOG
    EVENTO
  else
    ret=0
    echo "--> Finalizou com: Sucesso na Execucao do Backup Rman - Data: `date`" >> $ARQ_LOG
    EVENTO
  fi
else
  echo "--> Finalizou com: Erro na Execucao do Backup Rman - Data: `date`" >> $ARQ_LOG
  EVENTO
fi

if [ ${COPIA_REMOTA} = "S" ]
	then
	REMOTO
fi	

####################
# LIMPEZA DOS LOGS #
####################
find $DIR_LOG/RmanBackupFull* -mtime +30 -print -exec rm -f {} \; > /dev/null 2>&1
