#set -x
#!/bin/sh
####################################################################################
## Descricao: Rotina via Expdp (datapump) por:
##    Opcoes: owner -> Faz backup por owner.
##            full  -> Faz backup full da base.
##   Exemplo: sh BackupExpdp.sh $ORACLE_SID [OWNER|FULL] 1 1 1 1 [S|N] 1 [S|N]
####################################################################################
DISPLAY()
{
	echo "[`date '+%d/%m/%Y %T'`] $*" >> ${ARQ_LOG_GERAL}
}
####################################################################################
## CONTROLE DE EXECUCAO
####################################################################################
if [ -e ${DIR_BASE}/run_datapump_${ORACLE_SID}.control ];
then
	echo "" >> ${ARQ_LOG}
	echo `date '+%Y%m%d_%H%M'` - Control file exists, execution aborted >> ${ARQ_LOG_GERAL}
	echo "" >> ${ARQ_LOG}
else
	touch ${DIR_BASE}/run_datapump_${ORACLE_SID}.control >> ${ARQ_LOG_GERAL}
####################################################################################
## GERA OWNERS
####################################################################################
GERA_OWNER()
{
# Gerar Lista de todos os owner da base com tabelas (criar a tabela BKP_OWNER e inserir os owners que serao ignorados)
${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} 2>&1 > /dev/null <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${ARQ_OWNER}
SELECT OWNER FROM DBA_OBJECTS HAVING COUNT(*) > 0 AND UPPER(OWNER) NOT IN (SELECT UPPER(NOMOWN) FROM BKP_OWNER) GROUP BY OWNER;
spool off;
quit
EOF
	if [ "${?}" = "0" ]
	then
		DISPLAY "================================================================================================"
		DISPLAY "================================================"
		DISPLAY "Gera Lista de Usuarios.........................: OK"
		DISPLAY "================================================"
		for USER in `cat ${ARQ_OWNER}`
		do
			DISPLAY "...............................................: ${USER}"
		done
		DISPLAY "================================================"
	else
		DISPLAY "================================================================================================"
		DISPLAY "Gera Lista de Usuarios.........................: ERRO"
		DISPLAY "================================================"
	fi
}
####################################################################################
## CAPTURA SCN DA BASE
####################################################################################
CAPTURA_SCN()
{
# Capturar scn para gerar backup consistente
${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} 2>&1 > /dev/null <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${SCN_ATUAL}
select trim(to_char(current_scn)) from v\$database;
spool off;
quit
EOF
	if [ "${?}" = "0" ]
	then
		DISPLAY "Captura SCN atual da base de dados.............: OK"
		DISPLAY "SCN atual......................................: `cat ${SCN_ATUAL}`"
	else
		DISPLAY "Captura SCN atual da base de dados.............: ERRO"
	fi
}
####################################################################################
## GERA LISTA DE TABELAS
####################################################################################
GERAR_LST_ORA()
{
${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${DIR_TMP}/usuario.txt
SELECT DISTINCT(OWNER) FROM BKP_EXCLUI_TABELA;
spool off;
spool ${DIR_TMP}/bkp_exclui_tabela.txt
SELECT '"'||owner||'"."'||tabela||'"' FROM BKP_EXCLUI_TABELA GROUP BY OWNER,TABELA;
spool off;
quit
EOF
	achou=0
	if [ "$(cat ${TMP_FILE} | grep "ORA-31693")" != "" ];
	then
		cat ${TMP_FILE} | grep "ORA-31693" > ${ERRO}
		if [ "${TIPO}" = "OWNER" ];
		then
			awk '{print '${IDIOMA}'}' ${ERRO} > ${LOG_COMPARA}
			for i in `cat ${LOG_COMPARA}`
			do
				AC=`cat ${USER_TABLES} | grep -c ${i}`
				if [ ${AC} -ne 1 ];
				then
					echo ${i} >> ${LOG_COMPARA}.erro
					achou=1
				fi
			done
			elif [ "${TIPO}" = "FULL" ];
			then
				awk '{print '${IDIOMA}'}' ${ERRO} > ${LOG_COMPARA}
			for i in `cat ${LOG_COMPARA}`
			do
				AC=`cat ${USER_TABLES} | grep -c ${i}`
				if [ ${AC} -ne 1 ];
				then
					echo ${i} >> ${LOG_COMPARA}.erro
					achou=1
				fi
			done
			fi
			if [  "${achou}" = "0" ]
			then
				FIM_EXPORT=OK
			else
				FIM_EXPORT=ERRO
			fi
		else
			FIM_EXPORT=OK
	fi
}
####################################################################################
## GERA LISTA DE JOBS
####################################################################################
#GERA_LISTA_JOB()
#{
#${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} 2>&1 <<EOF
#whenever sqlerror exit sql.sqlcode ;
#set tab off
#set pagesize 0
#set linesize 80
#set feedback off
#set termout off
#spool ${ARQ_JOB}
#SELECT JOBNO FROM BKP_EXCLUI_JOB WHERE JOBNAME IS NULL ORDER BY JOBNO;
#spool off;
#spool ${ARQ_SCHED}
#SELECT ''||OWNER||'.'||JOBNAME||'' FROM BKP_EXCLUI_JOB WHERE JOBNO IS NULL ORDER BY OWNER,JOBNAME;
#spool off;
#quit
#EOF
#}
####################################################################################
## DESABILITA JOBS
####################################################################################
#DESABILITA_JOB()
#{
#	if [ -s ${ARQ_JOB}]
#	then
#		for JOB in `cat ${ARQ_JOB}`
#		do
#			${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE}
#			EXEC DBMS_JOB.BROKEN(${JOB},TRUE);
#			quit
#		done
#	elif [ -s ${ARQ_SCHED}]
#	then
#		for SCHED in `cat ${ARQ_SCHED}`
#		do
#			${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE}
#			EXEC DBMS_SCHEDULER.DISABLE(${SCHED});
#			quit
#		done
#	else
#		DISPLAY "Desabilita Jobs................................: SEM JOBS"
#	fi
#	if [ "${?}" = "0" ]
#	then
#		DISPLAY "================================================================================================"
#		DISPLAY "================================================"
#		DISPLAY "Desabilita Jobs................................: OK"
#		DISPLAY "================================================"
#	else
#		DISPLAY "================================================================================================"
#		DISPLAY "================================================"
#		DISPLAY "Desabilita Jobs................................: ERRO"
#		DISPLAY "================================================"
#	fi
#}
####################################################################################
## HABILITA JOBS
####################################################################################
#HABILITA_JOB()
#{
#	if [ -s ${ARQ_JOB}]
#	then
#		for JOB in `cat ${ARQ_JOB}`
#		do
#			${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE}
#			EXEC DBMS_JOB.BROKEN(${JOB},FALSE);
#			quit
#		done
#	elif [ -s ${ARQ_SCHED}]
#	then
#		for SCHED in `cat ${ARQ_SCHED}`
#		do
#			${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE}
#			EXEC DBMS_SCHEDULER.ENABLE(${SCHED});
#			quit
#		done
#	else
#		DISPLAY "Desabilita Jobs................................: SEM JOBS"
#	fi
#	if [ "${?}" = "0" ]
#	then
#		DISPLAY "================================================================================================"
#		DISPLAY "================================================"
#		DISPLAY "Habilita Jobs..................................: OK"
#		DISPLAY "================================================"
#	else
#		DISPLAY "================================================================================================"
#		DISPLAY "================================================"
#		DISPLAY "Habilita Jobs..................................: ERRO"
#		DISPLAY "================================================"
#	fi
#}
####################################################################################
## COPIA REMOTA
####################################################################################
REMOTO()
{
	if [ "${?}" != "0" ]
	then
		DISPLAY "================================================================================================"
		DISPLAY "================================================"
		DISPLAY "Inicio copia remota do Backup Datapump.........: ERRO"
		DISPLAY "================================================"
	else
		DISPLAY "================================================================================================"
		DISPLAY "================================================"
		DISPLAY "Inicio copia remota do Backup Datapump.........: OK"
		DISPLAY "================================================"
#       /sbin/mount.cifs //192.168.0.7/backup ${DIR_COPIA} -o username=${USER_COPIA},password=${SENHA_COPIA} >> ${ARQ_LOG_GERAL}
		ret=${?}
		if [ "${ret}" != "0" ]
		then
			DISPLAY "Mount filesystem remoto do Backup Datapump.....: ERRO"
			DISPLAY "================================================"
		else
			find ${DIR_DMP} -maxdepth 1 -name '*.gz' -print -exec cp -uv {} ${BKP_COPIA} \; >> ${ARQ_LOG_GERAL}
			find ${DIR_LOG} -maxdepth 1 -name '*.ok' -print -exec cp -uv {} ${LOG_COPIA} \; >> ${ARQ_LOG_GERAL}
			find ${DIR_LOG} -maxdepth 1 -name '*.erro' -print -exec cp -uv {} ${LOG_COPIA} \; >> ${ARQ_LOG_GERAL}
			find ${DIR_LOG} -maxdepth 1 -name '*.log' -print -exec cp -uv {} ${LOG_COPIA} \; >> ${ARQ_LOG_GERAL}
			find ${BKP_COPIA}/*.gz -mtime +${RETENCAO_COP} -print -exec rm -f {} \; > /dev/null 2>&1
			find ${LOG_COPIA}/*.ok -mtime +${RETENCAO_COP} -print -exec rm -f {} \; > /dev/null 2>&1
			find ${LOG_COPIA}/*.erro -mtime +${RETENCAO_COP} -print -exec rm -f {} \; > /dev/null 2>&1
			find ${LOG_COPIA}/*.log -mtime +${RETENCAO_COP} -print -exec rm -f {} \; > /dev/null 2>&1
			ret=${?}
			if [ "${ret}" != "0" ]
			then
				DISPLAY "Copia remota do Backup Datapump................: ERRO"
				DISPLAY "================================================"
			else
				DISPLAY "================================================"
				DISPLAY "Copia remota do Backup Datapump................: OK"
				DISPLAY "================================================"
			fi
#       /bin/umount ${DIR_COPIA} > /dev/null 2>&1
		fi
	fi
}
####################################################################################
## COPIA CLOUD
####################################################################################
CLOUD()
{
	if [ "${?}" != "0" ]
	then
		DISPLAY "================================================================================================"
		DISPLAY "================================================"
		DISPLAY "Inicio copia do Backup Datapump para a nuvem...: ERRO"
		DISPLAY "================================================"
	else
		DISPLAY "================================================================================================"
		DISPLAY "================================================"
		DISPLAY "Inicio copia do Backup Datapump para a nuvem...: OK"
		DISPLAY "================================================"
		if [ "${?}" != "0" ]
		then
			DISPLAY "Envio do Backup Datapump para a nuvem..........: ERRO"
			DISPLAY "================================================"
		else
			${DIR_CLOUD}/lb2cloud bkp --skip-duplicate -f oracle/datapump ${DIR_DMP}/${INSTANCE}.*.`date +%Y%m%d`*.gz >> ${ARQ_LOG_GERAL}
			${DIR_CLOUD}/lb2cloud bkp --skip-duplicate -f oracle/datapump ${DIR_LOG}/${INSTANCE}.*.`date +%Y%m%d`*.* >> ${ARQ_LOG_GERAL}
			ret={?}
			if [ "${ret}" = "0" ]
			then
				DISPLAY "Envio do Backup Datapump para a nuvem..........: ERRO"
				DISPLAY "================================================"
			else
				DISPLAY "================================================"
				DISPLAY "Envio do Backup Datapump para a nuvem..........: OK"
				DISPLAY "================================================"
			fi
		fi
	fi
}
####################################################################################
## EXPORT OWNER
####################################################################################
EXPORT_OWNER()
{
# Gera lista de jobs
#	GERA_LISTA_JOB
# Desabilita os jobs
#   DESABILITA_JOB
# Gera lista de usuarios com objetos
	GERA_OWNER
# Executa Expdp
	for USUARIO in `cat ${ARQ_OWNER}`
	do
# Captura SCN da base de dados
	DISPLAY "================================================================================================"
	DISPLAY "================================================"
	DISPLAY "Expdp do Usuario...............................: ${USUARIO}"
	DISPLAY "================================================"
	CAPTURA_SCN
	SCN=`cat ${SCN_ATUAL}`
	ARQ_LOG=${INSTANCE}.${USUARIO}.`date +%Y%m%d%H`
	export TMP_FILE=${DIR_TMP}/${INSTANCE}.${USUARIO}.`date +%Y%m%d%H`.tmp
	ARQ_DMP=${INSTANCE}.${USUARIO}%U.`date +%Y%m%d%H`.dmp
#   DISPLAY "Expdp do Usuario...............................: ${USUARIO}"
	DISPLAY "================================================"
	DISPLAY "Inicio.........................................: `date '+%d/%m/%Y %T'`"
# Comando EXPORT
	case ${ORACLE_VERSION} in
		11.1|11.2)
			expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} DIRECTORY=${DIR_BKP} FLASHBACK_SCN=${SCN} VERSION=${ORACLE_VERSION} SCHEMAS='\"'${USUARIO}'\"' DUMPFILE=${ARQ_DMP} LOGFILE=${ARQ_LOG} METRICS=${METRIC} CONTENT=${CONT} PARALLEL=${THREAD} REUSE_DUMPFILES=${REUSE_DUMP} < /dev/null 2>${TMP_FILE}
			;;
		12.1|12.2)
			expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} DIRECTORY=${DIR_BKP} FLASHBACK_SCN=${SCN} VERSION=${ORACLE_VERSION} SCHEMAS='\"'${USUARIO}'\"' DUMPFILE=${ARQ_DMP} LOGFILE=${ARQ_LOG} METRICS=${METRIC} LOGTIME=${LOG_TIME} CONTENT=${CONT} PARALLEL=${THREAD} REUSE_DUMPFILES=${REUSE_DUMP} < /dev/null 2>${TMP_FILE}
			;;
		*)
			expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} DIRECTORY=${DIR_BKP} FLASHBACK_SCN=${SCN} VERSION=${ORACLE_VERSION} SCHEMAS='\"'${USUARIO}'\"' DUMPFILE=${ARQ_DMP} LOGFILE=${ARQ_LOG} METRICS=${METRIC} CONTENT=${CONT} PARALLEL=${THREAD} REUSE_DUMPFILES=${REUSE_DUMP} < /dev/null 2>${TMP_FILE}
			;;
	esac
# Habilita os jobs
#   HABILITA_JOB
# Verifica se o backup foi executado com sucesso
	if [ -e ${DIR_DMP}/${ARQ_LOG} ]
	then
		if [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "${PROC_SUCESS}")" == "" ] || [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "ORA-" -e "EXP-" -e "error")" != "" ];
		then
			GERAR_LST_ORA
			FIM_EXPORT=ERRO
		else
			FIM_EXPORT=OK
		fi
	else
		FIM_EXPORT=ERRO
	fi
# Compacta arquivos .dmp
		gzip -f ${DIR_DMP}/*.dmp
# Verifica se a compactacao dos dumps foi efetuada com sucesso
		if [ "${?}" = "0" ]
		then
			FIM_COMPACTACAO=OK
		else
			FIM_COMPACTACAO=ERRO
		fi
# Verifica se todo o procedimento do backup de cada owner foi efetuado com sucesso
		if [ "${FIM_EXPORT}" = "OK" ] && [ "${FIM_COMPACTACAO}" = "OK" ]
		then
			mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.ok
			export STATUS=OK
			DISPLAY "Fim............................................: `date '+%d/%m/%Y %T'`"
			DISPLAY "================================================"
			DISPLAY "Status.........................................: ${STATUS}"
			DISPLAY "Log Execucao...................................: ${DIR_LOG}/${ARQ_LOG}.ok"
		else
			ERROR_COUNT=`expr $ERROR_COUNT + 1`
			export STATUS=ERRO
			DISPLAY "Fim............................................: `date '+%d/%m/%Y %T'`"
		if [ "${FIM_EXPORT}" != "OK" ]
		then
			DISPLAY "Export.........................................: ${FIM_EXPORT}"
		fi
		if [ "${FIM_COMPACTACAO}" != "OK" ]
		then
			DISPLAY "Compactacao....................................: ${FIM_COMPACTACAO}"
		fi
			mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.erro
			DISPLAY "Log Execucao...................................: ${DIR_LOG}/${ARQ_LOG}.erro"
			DISPLAY "Status.........................................: ${STATUS}"
		fi
		DISPLAY "================================================"
	done
# Gera o resumo geral do backup
        if [ "${ERROR_COUNT}" = "0" ]
        then
			STATUS_GERAL=OK
        else
			STATUS_GERAL=ERRO
        fi
			FIM_BACKUP="`date '+%d/%m/%Y %T'`"
			DISPLAY echo ""
			DISPLAY echo ""				
			DISPLAY "================================================================================================"
			DISPLAY "==================================  R E S U M O    G E R A L  =================================="
			DISPLAY "================================================================================================"
			DISPLAY "================================================"
			DISPLAY "Inicio do Backup...............................: ${INICIO_BACKUP}"
			DISPLAY "Fim do Backup..................................: ${FIM_BACKUP}"
			DISPLAY "================================================"
        if [ "${STATUS_GERAL}" != "OK" ]
        then
			DISPLAY "Owners com Erro................................: ${ERROR_COUNT}"
        fi
			DISPLAY "Status do Backup...............................: ${STATUS_GERAL}"
			DISPLAY "Log da Execucao do Backup......................: ${ARQ_LOG_GERAL}"
			DISPLAY "================================================"
}
####################################################################################
## EXPORT FULL
####################################################################################
EXPORT_FULL()
{
# Gera lista de jobs
#	GERA_LISTA_JOB
# Desabilita os jobs
#   DESABILITA_JOB
# Captura SCN da base de dados
	CAPTURA_SCN
	SCN=`cat ${SCN_ATUAL}`
	ARQ_LOG=${INSTANCE}.FULL.`date +%Y%m%d%H`.log
	ARQ_DMP=${INSTANCE}.FULL%U.`date +%Y%m%d%H`.dmp
	DISPLAY "************************************************"
	DISPLAY "************************************************"
	DISPLAY "***********  N O V O    B A C K U P  ***********"
	DISPLAY "************************************************"
	DISPLAY "************************************************"
	DISPLAY "Inicio do Backup Expdp.........................: ${PARAMETRO_LINHA}"
	DISPLAY "...............................................: Inicio"
# Comando EXPORT
	case ${ORACLE_VERSION} in
		11.1|11.2)
			expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} DIRECTORY=${DIR_BKP} FLASHBACK_SCN=${SCN} VERSION=${ORACLE_VERSION} FULL=Y DUMPFILE=${ARQ_DMP} LOGFILE=${ARQ_LOG} METRICS=${METRIC} CONTENT=${CONT} PARALLEL=${THREAD} REUSE_DUMPFILES=${REUSE_DUMP} < /dev/null 2>${TMP_FILE}
			;;
		12.1|12.2)
			expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} DIRECTORY=${DIR_BKP} FLASHBACK_SCN=${SCN} VERSION=${ORACLE_VERSION} FULL=Y DUMPFILE=${ARQ_DMP} LOGFILE=${ARQ_LOG} METRICS=${METRIC} LOGTIME=${LOG_TIME} CONTENT=${CONT} PARALLEL=${THREAD} REUSE_DUMPFILES=${REUSE_DUMP} < /dev/null 2>${TMP_FILE}
			;;
		*)
			expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@${INSTANCE} DIRECTORY=${DIR_BKP} FLASHBACK_SCN=${SCN} VERSION=${ORACLE_VERSION} FULL=Y DUMPFILE=${ARQ_DMP} LOGFILE=${ARQ_LOG} METRICS=${METRIC} CONTENT=${CONT} PARALLEL=${THREAD} REUSE_DUMPFILES=${REUSE_DUMP} < /dev/null 2>${TMP_FILE}
			;;
	esac
# Habilita os jobs
#   HABILITA_JOB
# Verifica se o backup foi executado com sucesso
	if [ -e ${DIR_DMP}/${ARQ_LOG} ]
	then
		if [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "${PROC_SUCESS}")" == "" ] || [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "ORA-" -e "EXP-" -e "error")" != "" ];
		then
			GERAR_LST_ORA
			FIM_EXPORT=ERRO
		else
			FIM_EXPORT=OK
		fi
	else
		FIM_EXPORT=ERRO
	fi

	if [ "${FIM_EXPORT}" = "OK" ]
	then
		DISPLAY "...............................................: Backup executado com sucesso"
	else
		DISPLAY "...............................................: Backup executado com erro"
	fi
# Compacta arquivos .dmp
	gzip -f ${DIR_DMP}/*.dmp
# Verifica se a compactacao dos dumps foi efetuada com sucesso
	if [ "${?}" = "0" ]
	then
		FIM_COMPACTACAO=OK
		DISPLAY "...............................................: Compactacao executado com sucesso"
	else
		FIM_COMPACTACAO=ERRO
		DISPLAY "...............................................: Compactacao executado com erro"
	fi
# Checa compactacao
	if [ "${FIM_EXPORT}" = "OK" ] && [ "${FIM_COMPACTACAO}" = "OK" ]
	then
		mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.ok
		echo "--> Finalizou com: Sucesso a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
	else
		mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.erro
		echo "--> Finalizou com: ERRO a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
	fi
		DISPLAY "================================================"
		DISPLAY "...............................................: Fim"
}
####################################################################################
## CONTROLE DE EXECUCAO
####################################################################################
INICIO_BACKUP="`date '+%d/%m/%Y %T'`"
	if [ `echo $#` -lt "8" ]
	then
		echo "Atencao: Falta de Parametros!!!
		sh BackupExpdp.sh <INSTANCE> <TIPO DE BACKUP> <RETENCAO DO BACKUP> <RETENCAO DA COMPACTACAO> <RETENCAO DO LOG> <COPIA REMOTA [S|N]> <RETENCAO DA COPIA> <COPIA CLOUD [S|N]>
		Opcoes: owner -> Faz backup por owner.
				full  -> Faz backup full da base.
		Exemplo:sh BackupExpdp.sh $ORACLE_SID owner/full 1 1 1 S 1 S"
		exit 3
	fi
# Parametros
		export INSTANCE=`echo $1`
		export TIPO=`echo $2 | tr "a-z" "A-Z"`
		export RETENCAO_DMP=`echo $3`
		export RETENCAO_TGZ=`echo $4`
		export RETENCAO_LOG=`echo $5`
		export COPIA_REMOTA=`echo $6 | tr "a-z" "A-Z"`
		export RETENCAO_COP=`echo $7`
		export COPIA_CLOUD=`echo $8 | tr "a-z" "A-Z"`
		export IDIOMA='$9'
# Definicao de variaveis do shell
	case ${INSTANCE} in
		viasoft) echo
			export ORACLE_BASE=/u01/app/oracle
			export ORACLE_HOME=${ORACLE_BASE}/product/11.2.0/db_1
			export PATH=/usr/sbin:${PATH}:/sbin:/home/oracle:${ORACLE_HOME}/bin/
			export ORACLE_OWNER=oracle
			export ORACLE_VERSION=11.2
			export ORACLE_SID=${INSTANCE}
			export ORACLE_TERM=xterm
			;;
		*) # Parametros Nao Definidos
			echo "Parametros nao Definidos para ORACLE_SID=${INSTANCE}"
		exit 4
	esac
SERVERNAME=`uname -n`
	if  [ ${SERVERNAME} = "DB-ORACLE" ]
	then
# Variaveis expdp
		export USER_EXPORT=LB2_BKP
		export USER_EXPORT_PASSWORD=bkp#lb2
		export DIR_BKP=DATA_PUMP
		export METRIC=Y                 #[Y | N]
		export LOG_TIME=ALL             #[NONE | STATUS | LOGFILE | ALL]
		export CONT=ALL                 #[ALL | METADATA_ONLY | DATA_ONLY]
		export THREAD=1                 #[1+]
		export REUSE_DUMP=Y             #[Y | N]
# Variaveis script
		export DIR_BASE=${ORACLE_BASE}/backup/datapump
		export DIR_DMP=${DIR_BASE}/files
		export DIR_LOG=${DIR_BASE}/logs
		export DIR_TMP=${DIR_BASE}/tmp
		export ARQ_LOG_PROCESSO=${DIR_TMP}/Export_processo.log
		export TMP_FILE=${DIR_TMP}/export_full_${INSTANCE}.tmp
		export USER_TABLES=${DIR_TMP}/bkp_exclui_tabela.txt
		export ERRO=${DIR_TMP}/Erro.log
		export LOG_COMPARA=${DIR_TMP}/ComparaTabela.txt
		export ARQ_LOG_GERAL=${DIR_LOG}/${INSTANCE}.EXPDP.${TIPO}.GERAL.`date +%Y%m%d%H`.log
		export ARQ_OWNER=${DIR_TMP}/Lista_owner_${INSTANCE}.tab
		export SCN_ATUAL=${DIR_TMP}/scn_${INSTANCE}.txt
		export ARQ_JOB=${DIR_TMP}/job.txt
		export ARQ_SCHED=${DIR_TMP}/sched.txt
#   export PROC_SUCESS="successfully completed"
		export PROC_SUCESS="com sucesso"
		export STATUS=OK
		export STATUS_GERAL=OK
# Variaveis copia remota
		export DIR_COPIA=/backup_remoto/datapump
		export BKP_COPIA=${DIR_COPIA}/files
		export LOG_COPIA=${DIR_COPIA}/logsG
#   export USER_COPIA=admin
#   export SENHA_COPIA=admin
# Variaveis copia cloud
		export DIR_CLOUD=/backup/scripts
	else
		echo " - Nome do servidor invalido : ${SERVERNAME}"
		exit 5
	fi
		DISPLAY "================================================"
		DISPLAY "Inicio do Backup ..............................: Expdp"
		DISPLAY "Parametros Recebidos...........................:"
		DISPLAY "--> Instancia..................................: ${INSTANCE}"
		DISPLAY "--> Tipo do Backup.............................: ${TIPO}"
		DISPLAY "--> Retencao dos DMPs..........................: ${RETENCAO_DMP}"
		DISPLAY "--> Retencao dos TGZs..........................: ${RETENCAO_TGZ}"
		DISPLAY "--> Retencao dos Logs..........................: ${RETENCAO_LOG}"
		DISPLAY "--> Retencao da Copia..........................: ${RETENCAO_COP}"
		DISPLAY "================================================"
	if [ "${TIPO}" = "OWNER" ]
	then
# Backup owner
# Copia remota
		ERROR_COUNT=0
		EXPORT_OWNER
		if [ ${COPIA_REMOTA} = 'S' ]
		then
			REMOTO
		fi
# Copia cloud        
		if [ ${COPIA_CLOUD} = 'S' ]
		then
			CLOUD
		fi
# backup full		
# Copia remota
		elif [ "${TIPO}" = "FULL" ]
		then
		EXPORT_FULL
		if [ ${COPIA_REMOTA} = 'S' ]
		then
			REMOTO
		fi
# Copia cloud          
		if [ ${COPIA_CLOUD} = 'S' ]
		then
			CLOUD
		fi
		else
			DISPLAY "Parametro Invalido..............................: TIPO=${TIPO}"
		exit 6;
	fi
####################################################################################
## MANUTENCAO BACKUPS
####################################################################################
	find ${DIR_TMP}/* -mtime -1 -print -exec rm -f {} \; > /dev/null 2>&1
	find ${DIR_LOG}/* -mtime +${RETENCAO_LOG} -print -exec rm -f {} \; > /dev/null 2>&1
	find ${DIR_DMP}/* -mtime +${RETENCAO_TGZ} -print -exec rm -f {} \; > /dev/null 2>&1
	rm -f ${DIR_BASE}/run_datapump_${ORACLE_SID}.control >> ${ARQ_LOG_GERAL}
fi	