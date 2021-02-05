#set -x
#!/bin/sh
####################################################################################
## Descricao: Rotina via Rman Full:
##   Exemplo: sh BackupRmanFull.sh $ORACLE_SID 1 [S|N] 1 [S|N]
####################################################################################
	. /etc/ambiente_${ORACLE_SID}.sh
####################################################################################
## CONTROLE DE EXECUCAO
####################################################################################
if [ -e ${DIR_BASE}/run_full_${ORACLE_SID}.control ];
then
	echo "" >> ${ARQ_LOG}
	echo `date '+%Y%m%d_%H%M'` - Control file exists, execution aborted >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
else
	touch ${DIR_BASE}/run_full_${ORACLE_SID}.control  >> ${ARQ_LOG}
####################################################################################
## CONFIGURA BACKUP
####################################################################################
	export DATA=`date '+%Y%m%d_%H%M'`
# Variaveis ambiente
	export ORACLE_BASE=/u01/app/oracle
	export ORACLE_HOME=${ORACLE_BASE}/product/11.2.0/db_1
	export PATH=/usr/sbin:${PATH}:/sbin:/home/oracle:${ORACLE_HOME}/bin/
# Variaveis script
	export DIR_BASE=${ORACLE_BASE}/backup/rman
	export DIR_BKP=${DIR_BASE}/files
	export DIR_LOG=${DIR_BASE}/logs
	export ARQ_LOG=${DIR_LOG}/RmanBackupFull_${ORACLE_SID}_${DATA}.log
# Variaveis RMAN
	export SIZE_BKP=5120M
	export SIZE_CTL=1024M
	export BKP_TAG='BackupDatabaseFullDiario'
	export CTL_TAG='BackupCurrentControlfile'
	export BKP_FORMAT=df_%d_%s_%p_%t_%T.dbf
	export CTL_FORMAT=cf_bkp_%d_%s_%p_%t_%T.ctl
# Variaveis copia remota
	export DIR_COPIA=/backup_remoto/rman/
	export BKP_COPIA=${DIR_COPIA}/files
	export LOG_COPIA=${DIR_COPIA}/logs
	export USER_COPIA=admin
	export SENHA_COPIA=admin
# Variaveis copia cloud
	export DIR_CLOUD=/backup/scripts
# Origem dos archives
	export OR_ARC=${ORACLE_BASE}/archives
	export OR_STB=${ORACLE_BASE}/standby
# Parametros
	export ORACLE_SID=`echo $1`
	export RET_BKP=`echo $2`
	export COPIA_REMOTA=`echo $3 | tr "a-z" "A-Z"`
	export RET_COPIA=`echo $4`
	export COPIA_CLOUD=`echo $5 | tr "a-z" "A-Z"`
####################################################################################
## COPIA REMOTA
####################################################################################
REMOTO ()
{
	echo "" >> ${ARQ_LOG}
	echo "==============================================" >> ${ARQ_LOG}
	echo "Inciando copia remota do Backup Rman Full" >> ${ARQ_LOG}
	echo "==============================================" >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
	#sudo mount 10.10.1.201:/repoveeam/backups/oracle /backup_remoto
	ret=${?}
	if [ "${ret}" != "0" ]
	then
		echo "Erro mount filesystem remoto do Backup" >> ${ARQ_LOG}
	else
		find ${DIR_BKP}/ -maxdepth 1 -name 'df_*.dbf' -print -exec cp -uv {} ${BKP_COPIA} \; >> ${ARQ_LOG}
		find ${DIR_BKP}/ -maxdepth 1 -name 'cf_bkp_*.ctl' -print -exec cp -uv {} ${BKP_COPIA} \; >> ${ARQ_LOG}
		find ${DIR_LOG}/ -maxdepth 1 -name '*Full_*.log' -print -exec cp -uv {} ${LOG_COPIA} \; >> ${ARQ_LOG}
		find ${BKP_COPIA}/df_*.dbf -mtime +${RET_COPIA} -print -exec rm -f {} \; > /dev/null 2>&1
		find ${BKP_COPIA}/cf_bkp_*.ctl -mtime +${RET_COPIA} -print -exec rm -f {} \; > /dev/null 2>&1
		find ${LOG_COPIA}/*Full_*.log -mtime +${RET_COPIA} -print -exec rm -f {} \; > /dev/null 2>&1
		ret=${?}
		if [ "${ret}" != "0" ]
		then
			echo "" >> ${ARQ_LOG}
			echo "Erro copia remota do Backup Rman Full" >> ${ARQ_LOG}
			echo "" >> ${ARQ_LOG}
		else
			echo "" >> ${ARQ_LOG}
			echo "Sucesso copia remota do Backup Rman Full" >> ${ARQ_LOG}
			echo "" >> ${ARQ_LOG}
		fi
	#sudo umount /backup_remoto
	fi
}
####################################################################################
## COPIA CLOUD
####################################################################################
CLOUD()
{
	echo "" >> ${ARQ_LOG}
	echo "==============================================" >> ${ARQ_LOG}
	echo "Inciando copia cloud do Backup Rman Full" >> ${ARQ_LOG}
	echo "==============================================" >> ${ARQ_LOG}
	if [ "${?}" != "0" ]
	then
		echo "Erro inicio copia cloud do Backup Rman Full" >> ${ARQ_LOG}
	else
		echo "Inicio copia cloud do Backup Rman Full"
		${DIR_CLOUD}/lb2cloud bkp --skip-duplicate -f oracle/rman ${DIR_BKP}/df_*.dbf >> ${ARQ_LOG}
		${DIR_CLOUD}/lb2cloud bkp --skip-duplicate -f oracle/rman ${DIR_BKP}/cf_bkp_*.ctl >> ${ARQ_LOG}
		${DIR_CLOUD}/lb2cloud bkp --skip-duplicate -f oracle/rman ${DIR_LOG}/*Full_*.log >> ${ARQ_LOG}
		ret={?}
		if [ "${ret}" = "0" ]
		then
			echo "" >> ${ARQ_LOG}
			echo "Erro copia cloud do Backup Rman Full" >> ${ARQ_LOG}
			echo "" >> ${ARQ_LOG}
		else
			echo "" >> ${ARQ_LOG}
			echo "Sucesso copia cloud do Backup Rman Full" >> ${ARQ_LOG}
			echo "" >> ${ARQ_LOG}
		fi
	fi
}
####################################################################################
## EXECUTA BACKUP
####################################################################################
	echo "" >> ${ARQ_LOG}
	echo "===========================================================================================" >> ${ARQ_LOG}
	echo "======================   I N I C I O   D O   B A C K U P   F U L L   ======================" >> ${ARQ_LOG}
	echo "===========================================================================================" >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
	echo "`date`" >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
	echo "===========================================================================================" >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
	if [ `echo $#` -lt "4" ]
	then
		echo "Atencao: Falta de Parametros!!!
		sh BackupRmanFull.sh <INSTANCE> <RETENCAO DO BACKUP> <COPIA REMOTA [S|N]> <RETENCAO DA COPIA> <COPIA CLOUD [S|N]>
		Exemplo:sh BackupRmanFull.sh $ORACLE_SID 1 S 5 S"
		exit 3
	fi
rman target / <<EOF 1>> ${ARQ_LOG} 2>> ${ARQ_LOG}
show all;
run {
CROSSCHECK BACKUP;
DELETE NOPROMPT EXPIRED BACKUP;
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF ${RET_BKP} DAYS;
ALLOCATE CHANNEL D1 TYPE DISK FORMAT '${DIR_BKP}/${BKP_FORMAT}' MAXPIECESIZE ${SIZE_BKP};
BACKUP AS COMPRESSED BACKUPSET TAG ${BKP_TAG} DATABASE;
RELEASE CHANNEL D1;
ALLOCATE CHANNEL D2 TYPE DISK FORMAT '${DIR_BKP}/${CTL_FORMAT}' MAXPIECESIZE ${SIZE_CTL};
BACKUP AS COMPRESSED BACKUPSET TAG ${CTL_TAG} CURRENT CONTROLFILE;
RELEASE CHANNEL D2;
}
exit
EOF
# Verifica se o backup foi executado com sucesso
		if [ -e ${ARQ_LOG} ]
		then
		# ERROS=`egrep "ORA-|RMAN-" ${ARQ_LOG} | wc -l`
			ERROS=`egrep "ORA-|RMAN-" ${ARQ_LOG} | egrep -v "RMAN-08138" | wc -l`
			if [ "${ERROS}" -gt "0" ]
			then
				RET=1
				echo "" >> ${ARQ_LOG}
				echo "===========================================================================================" >> ${ARQ_LOG}
				echo "--> Backup Rman Full finalizado com: ERRO     ==  `date`          <--" >> ${ARQ_LOG}
				echo "===========================================================================================" >> ${ARQ_LOG}
			else
				RET=0
				echo "" >> ${ARQ_LOG}
				echo "===========================================================================================" >> ${ARQ_LOG}
				echo "--> Backup Rman Full finalizado com: SUCESSO  ==  `date`          <--" >> ${ARQ_LOG}
				echo "===========================================================================================" >> ${ARQ_LOG}
			fi
		else
			RET=1
		fi
		# Copia remota
		if [ ${COPIA_REMOTA} = "S" ]
		then
			REMOTO
		fi
		# Copia cloud
		if [ ${COPIA_CLOUD} = "S" ]
		then
			CLOUD
		fi
	echo "===========================================================================================" >> ${ARQ_LOG}
	echo "=========================   F I M   D O   B A C K U P   F U L L   =========================" >> ${ARQ_LOG}
	echo "===========================================================================================" >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
	echo "`date`" >> ${ARQ_LOG}
	echo "" >> ${ARQ_LOG}
####################################################################################
## MANUTENCAO BACKUP
####################################################################################
	find ${DIR_BKP}/df_*.dbf -mtime +${RET_BKP} -print -exec rm -f {} \; > /dev/null 2>&1
	find ${DIR_BKP}/cf_bkp_*.ctl -mtime +${RET_BKP} -print -exec rm -f {} \; > /dev/null 2>&1
	find ${DIR_LOG}/*Full_*.log -mtime +${RET_BKP} -print -exec rm -f {} \; > /dev/null 2>&1
	rm -f ${DIR_BASE}/run_full_${ORACLE_SID}.control  >> ${ARQ_LOG}
fi