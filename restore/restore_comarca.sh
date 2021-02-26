#set -x
#!/bin/sh
#===========================================================================================================
#  Autor: Rafael Oliveira
# Resumo: Realiza restore das comarcas
#===========================================================================================================

DATA=`date +%d%m%Y`
ENDERECO=`echo ${2}`
COMARCA=`echo ${1} | tr "A-Z" "a-z"`
BKP=/backup-disco
SCRIPTS=/tmp/scripts_codap
RST=${BKP}/restore
SCM=~siscom
CT_ARQUIVO=`ls ${RST} | wc -l | sed 's/ *//'`
CT_PASTA=`ls -l ${RST} | grep -c ^d | sed 's/ *//'`
COUNT=4
UPD_LOCK=${SCM}/update.lock
RST_LOCK=${SCRIPTS}/restore.lock
LOG=${SCRIPTS}/logs/${DATA}_RESTORE_BD_${COMARCA}.log
H_NAME=`host ${ENDERECO} | sed 's/^.*${COMARCA}//g' | sed 's/-1.*//g'`
H_ADDR=`ifconfig -au | sed '/${ENDERECO}/,$!d' | sed 's/^.*inet//g' | sed 's/netmask.*//g' | sed 's/ *//'`

#==========================================================================================================
#========= FAZER A COPIA DOS CONTROLFILES
#==========================================================================================================
COPIA_CONTROLFILE()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Criando backup dos controlfiles:" >> ${LOG} 2>&1
		for CTL in $(find /ora*/oradata/P/ -name control*.ctl);
			cp "${CTL}" "${CTL}".bkp  >> ${LOG} 2>&1
		done
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Backup criado." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= TRAVAR O SISTEMA SISCOM
#==========================================================================================================
TRAVA_SISCOM()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Bloqueando acesso ao SISCOM:" >> ${LOG} 2>&1
		su siscom >> ${LOG} 2>&1
		if [[ -f "${UPD_LOCK}" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo já existe." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		else
			touch ${UPD_LOCK} >> ${LOG} 2>&1
			if [[ -f "${UPD_LOCK}" ]];
			then
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Acesso bloqueado." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Criacao do arquivo de bloqueio falhou." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				exit 1;
			fi
		fi
	}
#==========================================================================================================
#========= DESTRAVAR O SISTEMA SISCOM
#==========================================================================================================
DESTRAVA_SISCOM()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Desbloqueando acesso ao SISCOM:" >> ${LOG} 2>&1
		su siscom >> ${LOG} 2>&1
		if [[ ! -f "${UPD_LOCK}" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo nao existe." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		else
			rm -f ${UPD_LOCK} >> ${LOG} 2>&1
			if [[ ! -f "${UPD_LOCK}" ]];
			then
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Acesso desbloqueado." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Remocao do arquivo de bloqueio falhou." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				exit 1;
			fi
		fi
	}
#==========================================================================================================
#========= DELETAR OS ARQUIVOS ANTES DA COPIA DOS BACKUPS
#==========================================================================================================
DELETA_ARQUIVO()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Apagando arquivos antigos de restore:" >> ${LOG} 2>&1
		if [[ -n ls "${RST}/" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Nao existem arquivos antigos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			rm -rf ${RST}/* >> ${LOG} 2>&1
			if [[ -n ls "$(/backup-disco/restore/)" ]];
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos apagados." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na remocao dos arquivos." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				exit 1;
			fi
		fi
	}
#==========================================================================================================
#========= COPIAR OS BACKUPS
#==========================================================================================================
COPIA_BACKUP()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Copiando arquivos de backup:" >> ${LOG} 2>&1
		for ARQUIVO in {1..4};
		do
			cp ${BKP}/ora"${ARQUIVO}".tgz ${RST}/ >> ${LOG} 2>&1
		done
		if [[ ${CT_ARQUIVO} = "${COUNT}" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos copiados." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na copia dos arquivos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#==========================================================================================================
#========= DESCOMPACTAR OS BACKUPS
#==========================================================================================================
DESCOMPACTA_BACKUP()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Descompactando arquivos de backup:" >> ${LOG} 2>&1
		for PASTA in {1..4};
		do
			gtar -xvf ${RST}/ora"${PASTA}".tgz -C ${RST}/ >> ${LOG} 2>&1
		done
		if [[ ${CT_PASTA} = "${COUNT}" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos descompactados." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na descompactacao dos arquivos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#==========================================================================================================
#========= COPIAR OS DATAFILES
#==========================================================================================================
COPIA_DATAFILE()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Copiando datafiles para o destino:" >> ${LOG} 2>&1
		for FILE in {1..4};
		do
			cp -p ${RST}/ora"${FILE}"/oradata/P/*.dbf /ora"${FILE}"/oradata/P/
		done
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Datafiles copiados." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= RESTAURAR O BANCO DE DADOS
#==========================================================================================================
RESTAURA_BANCO()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Restaurando o banco de dados:" >> ${LOG} 2>&1
		su - oracle -c svrmgrl >> ${LOG} 2>&1 <<-EOF
		connect internal;
		startup mount;
		recover database;
		AUTO;
		alter database open;
		quit;
		EOF
		if [[ $? =~ "Recover finished successfully" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco de dados restaurado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na restauracao do banco de dados." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#==========================================================================================================
#========= DESLIGAR O BANCO DE DADOS
#==========================================================================================================
DESLIGA_BANCO()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Desligando o banco de dados:" >> ${LOG} 2>&1
		su - oracle -c svrmgrl >> ${LOG} 2>&1 <<-EOF
		connect internal;
		shutdown immediate;
		quit;
		EOF
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco de dados desligado." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= LIGAR O BANCO DE DADOS
#==========================================================================================================
LIGA_BANCO()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Ligando o banco de dados:" >> ${LOG} 2>&1
		su - oracle -c svrmgrl >> ${LOG} 2>&1 <<-EOF
		connect internal;
		startup;
		quit;
		EOF
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco de dados ligado." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= EFETUAR A EXECUCAO DOS MODULOS
#==========================================================================================================
EXECUTA_SCRIPT()
	{
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Inicio do processo de restore do banco de dados" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		DESLIGA_BANCO
		COPIA_CONTROLFILE
		TRAVA_SISCOM
		DELETA_ARQUIVO
		COPIA_BACKUP
		DESCOMPACTA_BACKUP
		COPIA_DATAFILE
		RESTAURA_BANCO
		DESLIGA_BANCO
		LIGA_BANCO
		DESTRAVA_SISCOM
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Fim do processo de restore do banco de dados" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EXECUTAR PROCESSO DE RESTORE
#===========================================================================================================
if [[ ${H_NAME} = ${COMARCA} ]] && [[ ${H_ADDR} = ${ENDERECO} ]];
then
	if [[ ! -f "${RST_LOCK}" ]];
	then
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "Comarca: ${COMARCA}" >> ${LOG} 2>&1
		echo -e "IP: ${ENCERECO}" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e >> ${LOG} 2>&1
		touch ${RST_LOCK} >> ${LOG} 2>&1
		EXECUTA_SCRIPT
		rm -f ${RST_LOCK} >> ${LOG} 2>&1
	else
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo de controle encontrado." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Execucao abortada." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		exit 1;
	fi
else
	echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] IP ou COMARCA incorreto." >> ${LOG} 2>&1
	echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	exit 1;
fi
