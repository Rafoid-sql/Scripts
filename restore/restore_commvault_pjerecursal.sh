#set -x
#!/bin/sh
#===========================================================================================================
#  Autor: Rafael Oliveira
# Resumo: Realiza Restore Commvault no Banco PJE-SUP
#===========================================================================================================

HNAME=`hostname -s | sed 's/-//g'`
DATA=`date +%d%m%Y`
GALAXY_BASE=${GALAXY_BASE:-/opt/commvault/Base}
export PATH=${PATH}:${GALAXY_BASE}
SCP_BASE=/backup
SCP_DIR=/${SCP_BASE}/pre-pos_restore_pje
SCP_LOG=${SCP_DIR}/log
RESPONSE=${SCP_LOG}/restore_commvault_pjerecursal.tmp
ISJOB=`grep -c "jobIds" "${RESPONSE}"`
LOCK_COMM=${SCP_LOG}/commvault.lock
LOCK_PRE=${SCP_LOG}/pre_copia.lock
LOCK_POS=${SCP_LOG}/pos_copia.lock
LOG=${SCP_LOG}/${DATA}_COMMVAULT_PJE-SUP.log
TAG_DATA=`date +"%Y-%m-%d %H:%M:%S"`
TAG_NEW_VALUE=${TAG_DATA}
TAG_FILE='restore_commvault_pjerecursal.xml'
TAG_TEMP_FILE='temp_commvault_pjerecursal.xml'
TAG_1='toTimeValue'
TAG_VALUE_1=$(grep "<${TAG_1}>.*<.${TAG_1}>" ${TAG_FILE} | sed -e "s/^.*<${TAG_1}/<${TAG_1}/" | cut -f2 -d">"| cut -f1 -d"<")
TAG_2='timeValue'
TAG_VALUE_2=$(grep -m 1 "<${TAG_2}>.*<.${TAG_2}>" ${TAG_FILE} | sed -e "s/^.*<${TAG_2}/<${TAG_2}/" | cut -f2 -d">"| cut -f1 -d"<")

#===========================================================================================================
#========= ALTERA DATAS PARA O TIMESTAMP ATUAL
#===========================================================================================================
ALTERA_DATA()
	{
		sed -e "s/<${TAG_1}>${TAG_VALUE_1}<\/${TAG_1}>/<${TAG_1}>${TAG_NEW_VALUE}<\/${TAG_1}>/g" ${TAG_FILE} > ${TAG_TEMP_FILE}
		mv ${TAG_TEMP_FILE} ${TAG_FILE}
		sed -e "s/<${TAG_2}>${TAG_VALUE_2}<\/${TAG_2}>/<${TAG_2}>${TAG_NEW_VALUE}<\/${TAG_2}>/g" ${TAG_FILE} > ${TAG_TEMP_FILE}
		mv ${TAG_TEMP_FILE} ${TAG_FILE}
	}
#===========================================================================================================
#========= EXECUTA LOGIN NO COMMVAULT
#===========================================================================================================
EFETUA_LOGIN()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Efetuando login no Commvault:" >> ${LOG} 2>&1
		qlogin -u "TJMG\p0103617" -ps "332574b0118c15bc0f8c4a53e4fbe3f0054215cdbe444092c" -cs "w2k12commserve.ad.tjmg.jus.br" -csn "w2k12commserve"
		if [[ $? = "0" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Login efetuado com sucesso." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Falha na tentativa de login." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_COMM} >> ${LOG} 2>&1
			exit;
		fi
	}
#===========================================================================================================
#========= EXECUTA LOGOUT NO COMMVAULT
#===========================================================================================================
EFETUA_LOGOUT()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Efetuando logout no Commvault:" >> ${LOG} 2>&1
		qlogout
		if [[ $? = "0" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Logout efetuado com sucesso." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Falha na tentativa de logout." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_COMM} >> ${LOG} 2>&1
			exit;
		fi
		rm -f ${RESPONSE}
	}
#===========================================================================================================
#========= PARA EXECUCAO
#===========================================================================================================
PARA_EXECUCAO()
	{
		pkill -f restore_commvault_pjerecursal.sh
		rm -f ${LOCK_COMM} >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Execucao Abortada." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EXECUTA RESTAURACAO NO COMMVAULT
#===========================================================================================================
RESTAURA_BANCO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Iniciando o processo de restore:" >> ${LOG} 2>&1
		qoperation execute -af "${TAG_FILE}" "${@}" > ${RESPONSE} 2>&1
		if [[ $? = "0" ]];
		then
			${ISJOB}
			if [[ ${ISJOB} != 0 ]];
			then
				cat ${RESPONSE} | xargs | \
				while read line
				do
					echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] COMMVAULT JOB ID: `echo "${line}" | sed 's/^.*val=//' | sed 's/\/.*//'`." >> ${LOG} 2>&1
				done
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Restore em execucao..." >> ${LOG} 2>&1
				cat ${RESPONSE} | xargs | \
				while read line
				do
					qlist job -j `echo "${line}" | sed 's/^.*val=//' | sed 's/\/.*//'` -waitForJobComplete >> ${LOG} 2>&1
					RET=$(tail -n 3 ${LOG} | xargs)
					case ${RET} in
						*Killed*)
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Restore cancelado." >> ${LOG} 2>&1
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
							PARA_EXECUCAO
							break;
							;;
						*Suspended*)
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Restore pausado." >> ${LOG} 2>&1
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
							PARA_EXECUCAO
							break;
							;;
						*Finished*)
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Restore finalizado." >> ${LOG} 2>&1
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
							break;
							;;
						*Error 0x205:*)
							continue
							;;
						*QSDK*|*Failed*|*job:*|*Error*)
							continue
							;;
						*)
							echo -e "" >> ${LOG} 2>&1
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Verificar o status do restore." >> ${LOG} 2>&1
							echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
							PARA_EXECUCAO
							break;
							;;
					esac
				done
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na verificacao do job de restore." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				rm -f ${LOCK_COMM} >> ${LOG} 2>&1
				exit;
			fi
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na inicializacao do restore." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_COMM} >> ${LOG} 2>&1
			exit;
		fi
	}
#===========================================================================================================
#========= LIMPA LOGS ANTIGOS
#===========================================================================================================
REMOVE_LOG()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Removendo logs antigos:" >> ${LOG} 2>&1
		find ${SCP_LOG}/ -name '*_COMMVAULT_PJE-SUP.log' -mtime +30 -print -exec rm -f {} \; >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Logs removidos." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EFETUA A EXECUCAO DOS MODULOS
#===========================================================================================================
EXECUTA_SCRIPT()
	{
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Inicio do processo de Restore Commvault" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		ALTERA_DATA
		EFETUA_LOGIN
		RESTAURA_BANCO
		EFETUA_LOGOUT
		REMOVE_LOG
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Fim do processo de Restore Commvault" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EXECUTA PROCESSO DE RESTAURACAO
#===========================================================================================================
case ${HNAME} in
	linbdpje30|linbdpjeopcc1)
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "Servidor: `hostname -s | tr a-z A-Z`" >> ${LOG} 2>&1
		echo -e "Hostname: ${HOSTNAME} | (`hostname -i`)" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e >> ${LOG} 2>&1
		if [[ -e ${LOCK_PRE} ]] || [[ -e ${LOCK_COMM} ]] || [[ -e ${LOCK_POS} ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo de controle encontrado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Execucao abortada." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Favor verificar." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		else
			touch ${LOCK_COMM} >> ${LOG} 2>&1
			EXECUTA_SCRIPT
			rm -f ${LOCK_COMM} >> ${LOG} 2>&1
			exit;
		fi
		;;
	linbdpje20|linbdpje21)
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "Servidor: `hostname -s | tr a-z A-Z`" >> ${LOG} 2>&1
		echo -e "Hostname: ${HOSTNAME} | (`hostname -i`)" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e >> ${LOG} 2>&1
		echo -e "Ambiente de PRODUCAO." >> ${LOG} 2>&1
		echo -e "Execucao abortada." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		exit 4;
		;;
	*)
		echo -e "Servidor `hostname -s | tr a-z A-Z` invalido." >> ${LOG} 2>&1
		echo -e "Execucao abortada." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		exit 5;
		;;
esac