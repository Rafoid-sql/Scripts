#set -x
#!/bin/sh
#===========================================================================================================
#  Autor: Rafael Oliveira
# Resumo: Realiza restore das comarcas
#===========================================================================================================

DATA=`date +%d%m%Y`
ENDERECO=`echo ${1}`
COMARCA=`echo ${2}`
BKP=/backup-disco
SCRIPTS=/tmp/scripts
RST=${BKP}/restore
SCM=`~siscom`
CT_ARQUIVO=`ls "${RST}/" | wc -l | sed 's/ *//'`
CT_PASTA=`ls -l "${RST}/" | grep -c ^d | sed 's/ *//'`
COUNT=4
UPD_LOCK=${SCM}/update.lock
RST_LOCK=${SCRIPTS}/restore.lock
LOG=${SCRIPTS}/log/${DATA}_restore_bd_"${COMARCA}".log
# H_NAME=`host ${ENDERECO} | sed 's/^.*sol//g' | sed 's/-1.*//g'`
# H_ADDR=`ifconfig -au | sed '/${ENDERECO}/,$!d' | sed 's/^.*inet//g' | sed 's/netmask.*//g' | sed 's/ *//' | head -1`

#==========================================================================================================
#========= FAZER A COPIA DOS CONTROLFILES
#==========================================================================================================
COPIA_CONTROLFILE()
	{
		echo "Criando backup dos controlfiles:" >> ${LOG} 2>&1
		for CTL in `find /ora* -name control*.ctl`;
		do
			cp "${CTL}" "${CTL}".bkp >> ${LOG} 2>&1
			find /ora* -name control*.ctl.bkp >> ${LOG} 2>&1
		done
		echo "Backup criado." >> ${LOG} 2>&1
		echo "==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= TRAVAR O SISTEMA SISCOM
#==========================================================================================================
TRAVA_SISCOM()
	{
		echo "Bloqueando acesso ao SISCOM:" >> ${LOG} 2>&1
		su siscom >> ${LOG} 2>&1
		cd ${SCM}
		if -f "${UPD_LOCK}";
		then
			echo "Arquivo já existe." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
			exit 1;
		else
			touch ${UPD_LOCK} >> ${LOG} 2>&1
			if -f "${UPD_LOCK}";
			then
				echo "Acesso bloqueado." >> ${LOG} 2>&1
				echo "==============================================" >> ${LOG} 2>&1
			else
				echo "Criacao do arquivo de bloqueio falhou." >> ${LOG} 2>&1
				echo "==============================================" >> ${LOG} 2>&1
				exit 1;
			fi
		fi
		cd ${SCRIPTS}
	}
#==========================================================================================================
#========= DESTRAVAR O SISTEMA SISCOM
#==========================================================================================================
DESTRAVA_SISCOM()
	{
		echo "Desbloqueando acesso ao SISCOM:" >> ${LOG} 2>&1
		su siscom >> ${LOG} 2>&1
		cd ${SCM}
		if ! -f "${UPD_LOCK}";
		then
			echo "Arquivo nao existe." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
			exit 1;
		else
			rm -f ${UPD_LOCK} >> ${LOG} 2>&1
			if ! -f "${UPD_LOCK}";
			then
				echo "Acesso desbloqueado." >> ${LOG} 2>&1
				echo "==============================================" >> ${LOG} 2>&1
			else
				echo "Remocao do arquivo de bloqueio falhou." >> ${LOG} 2>&1
				echo "==============================================" >> ${LOG} 2>&1
				exit 1;
			fi
		fi
		cd ${SCRIPTS}
	}
#==========================================================================================================
#========= DELETAR OS ARQUIVOS ANTES DA COPIA DOS BACKUPS
#==========================================================================================================
DELETA_ARQUIVO()
	{
		echo "Apagando arquivos antigos de restore:" >> ${LOG} 2>&1
		if -n ls "${RST}/";
		then
			echo "Nao existem arquivos antigos." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
		else
			rm -rf ${RST}/* >> ${LOG} 2>&1
			if -n ls "$(/backup-disco/restore/)";
			then
				echo "Arquivos apagados." >> ${LOG} 2>&1
				echo "==============================================" >> ${LOG} 2>&1
			else
				echo "Problema na remocao dos arquivos." >> ${LOG} 2>&1
				echo "==============================================" >> ${LOG} 2>&1
				exit 1;
			fi
		fi
	}
#==========================================================================================================
#========= COPIAR OS BACKUPS
#==========================================================================================================
COPIA_BACKUP()
	{
		echo "Copiando arquivos de backup:" >> ${LOG} 2>&1
		for ARQUIVO in {1..4};
		do
			cp ${BKP}/ora"${ARQUIVO}".tgz ${RST}/ >> ${LOG} 2>&1
		done
		if "${CT_ARQUIVO}" = "${COUNT}";
		then
			echo "Arquivos copiados." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
		else
			echo "Problema na copia dos arquivos." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#==========================================================================================================
#========= DESCOMPACTAR OS BACKUPS
#==========================================================================================================
DESCOMPACTA_BACKUP()
	{
		echo "Descompactando arquivos de backup:" >> ${LOG} 2>&1
		for PASTA in {1..4};
		do
			gtar -xvf ${RST}/ora"${PASTA}".tgz >> ${LOG} 2>&1
		done
		if "${CT_PASTA}" = "${COUNT}";
		then
			echo "Arquivos descompactados." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
		else
			echo "Problema na descompactacao dos arquivos." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#==========================================================================================================
#========= COPIAR OS DATAFILES
#==========================================================================================================
COPIA_DATAFILE()
	{
		echo "Copiando datafiles para o destino:" >> ${LOG} 2>&1
		su - oracle
		for FILE in {1..4};
		do
			cp -p ${RST}/ora"${FILE}"/oradata/P/*.dbf /ora"${FILE}"/oradata/P/
		done
		echo "Datafiles copiados." >> ${LOG} 2>&1
		echo "==============================================" >> ${LOG} 2>&1
		exit
	}
#==========================================================================================================
#========= RESTAURAR O BANCO DE DADOS
#==========================================================================================================
RESTAURA_BANCO()
	{
		echo "Restaurando o banco de dados:" >> ${LOG} 2>&1
		su - oracle -c svrmgrl >> ${LOG} 2>&1 <<-EOF
		connect internal;
		startup mount;
		recover database;
		AUTO;
		alter database open;
		quit;
		EOF
		if $? =~ "Recover finished successfully";
		then
			echo "Banco de dados restaurado." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
		else
			echo "Problema na restauracao do banco de dados." >> ${LOG} 2>&1
			echo "==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#==========================================================================================================
#========= DESLIGAR O BANCO DE DADOS
#==========================================================================================================
DESLIGA_BANCO()
	{
		echo "Desligando o banco de dados:" >> ${LOG} 2>&1
		su - oracle -c svrmgrl >> ${LOG} 2>&1 <<-EOF
		connect internal;
		shutdown immediate;
		quit;
		EOF
		echo "Banco de dados desligado." >> ${LOG} 2>&1
		echo "==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= LIGAR O BANCO DE DADOS
#==========================================================================================================
LIGA_BANCO()
	{
		echo "Ligando o banco de dados:" >> ${LOG} 2>&1
		su - oracle -c svrmgrl >> ${LOG} 2>&1 <<-EOF
		connect internal;
		startup;
		quit;
		EOF
		echo "Banco de dados ligado." >> ${LOG} 2>&1
		echo "==============================================" >> ${LOG} 2>&1
	}
#==========================================================================================================
#========= EFETUAR A EXECUCAO DOS MODULOS
#==========================================================================================================
EXECUTA_SCRIPT()
	{
		echo "============================================================================================" >> ${LOG} 2>&1
		echo "Inicio do processo de restore da comarca ${COMARCA} | tr "a-z" "A-Z"" >> ${LOG} 2>&1
		echo "============================================================================================" >> ${LOG} 2>&1
		DESLIGA_BANCO
		COPIA_CONTROLFILE
		#TRAVA_SISCOM
		#DELETA_ARQUIVO
		#COPIA_BACKUP
		#DESCOMPACTA_BACKUP
		#COPIA_DATAFILE
		#RESTAURA_BANCO
		#DESLIGA_BANCO
		#LIGA_BANCO
		#DESTRAVA_SISCOM
		echo "============================================================================================" >> ${LOG} 2>&1
		echo "Fim do processo de restore da comarca ${COMARCA}" >> ${LOG} 2>&1
		echo "============================================================================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EXECUTAR PROCESSO DE RESTORE
#===========================================================================================================
# if ${H_NAME} = ${COMARCA} ]] && [[ ${H_ADDR} = ${ENDERECO};
# then
	if ! -f "${RST_LOCK}";
	then
		echo "============================================================================================" >> ${LOG} 2>&1
		echo "Comarca: ${COMARCA}" >> ${LOG} 2>&1
		echo "IP: ${ENDERECO}" >> ${LOG} 2>&1
		echo "============================================================================================" >> ${LOG} 2>&1
		echo >> ${LOG} 2>&1
		touch ${RST_LOCK} >> ${LOG} 2>&1
		EXECUTA_SCRIPT
		rm -f ${RST_LOCK} >> ${LOG} 2>&1
	else
		echo "Arquivo de controle encontrado." >> ${LOG} 2>&1
		echo "Execucao abortada." >> ${LOG} 2>&1
		echo "==============================================" >> ${LOG} 2>&1
		exit 1;
	fi
# else
	# echo "IP ou COMARCA incorreto." >> ${LOG} 2>&1
	# echo "==============================================" >> ${LOG} 2>&1
	# exit 1;
# fi