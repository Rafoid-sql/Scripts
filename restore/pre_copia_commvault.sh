#set -x
#!/bin/sh
#===========================================================================================================
#  Autor: Rafael Oliveira
# Resumo: Realiza Pre Copia Banco PJE-SUP
#===========================================================================================================

HNAME=`hostname -s | sed 's/-//g'`
SCP_BASE=/backup
SCP_DIR=/${SCP_BASE}/pre-pos_restore_pje
PG_SQLBIN=/usr/edb/as11/bin
PG_SQL=/pgsql2/pje_PRD_11
PG_CONF=${SCP_BASE}/conf_sup/conf
PG_LOG=${PG_SQL}/pg_wal
PG_BKP=${SCP_DIR}/arquivos
PG_H_REC=`ls -t ${PG_BKP}/pg_hba_*.conf | head -n 1`
PG_P_REC=`ls -t ${PG_BKP}/postgresql_*.conf | head -n 1`
ARC_DIR=${SCP_BASE}/bart/${HNAME}
ARC_W=${ARC_DIR}/archived_wals
ARC_WO=${ARC_DIR}/archived_wals_old
LOCK_PRE=${SCP_DIR}/pre_copia.lock
LOCK_POS=${SCP_DIR}/pos_copia.lock
DATA=`date +%d%m%Y`
SLP='15'
DESTINO=`hostname -i`
COUNT='1'
LOG=${SCP_DIR}/log/${DATA}_PRE_COPIA_PJE-SUP.log

#===========================================================================================================
#========= DESLIGA O BANCO DE DADOS
#===========================================================================================================
DESLIGA_BANCO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Desligando o Banco de Dados:" >> ${LOG} 2>&1
		STP=$(DB_STATUS)
		if [[ ${STP} =~ "pg_ctl: server is running" ]];
		then
			${PG_SQLBIN}/pg_ctl -D ${PG_SQL} stop -m immediate >> ${LOG} 2>&1
			STP=$(DB_STATUS)
			if [[ ${STP} = "pg_ctl: no server running" ]];
			then
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco desligado com sucesso." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema no desligamento do banco." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				rm -f ${LOCK_PRE} >> ${LOG} 2>&1
				exit 1;
			fi
		elif [[ ${STP} = "pg_ctl: no server running" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco ja se encontra desligado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		elif [[ ${STP} =~ "not a database cluster directory" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Operacao de pre copia ja executada." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_PRE} >> ${LOG} 2>&1
			exit 1;
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema no desligamento do banco." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_PRE} >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= CRIA BACKUP DOS ARQUIVOS PG_HBA.CONF E POSTGRESQL.CONF
#===========================================================================================================
COPIA_ARQUIVO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Criando backup dos arquivos pg_hba.conf e postgresql.conf:" >> ${LOG} 2>&1
		if [[ -e ${PG_SQL}/pg_hba.conf && ${PG_SQL}/postgresql.conf ]];
		then
			cp ${PG_SQL}/pg_hba.conf ${PG_BKP}/pg_hba_${DATA}.conf >> ${LOG} 2>&1
			cp ${PG_SQL}/postgresql.conf ${PG_BKP}/postgresql_${DATA}.conf >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Backup criado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos nao existem." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= VERIFICA PROCESSOS LENDO ARQUIVOS NO DIRETORIO /PGSQL2
#===========================================================================================================
VERIFICA_PROCESSO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Verificando processos utilizando arquivos do diretorio ${PG_SQL}:" >> ${LOG} 2>&1
		fuser –mk ${PG_SQL}/* >> ${LOG} 2>&1
		if [[ ${?} =~ "does not exist" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Nao existiam processos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Processos removidos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		fi
	}
#===========================================================================================================
#========= REMOVE O CONTEUDO DO DIRETORIO /PGSQL2
#===========================================================================================================
REMOVE_CONTEUDO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Removendo o conteudo do diretorio ${PG_SQL}:" >> ${LOG} 2>&1
		rm -rf ${PG_SQL}/* >> ${LOG} 2>&1
		if [[ -z "$(ls -A ${PG_SQL}/)" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Conteudo removido." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Falha na remocao." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= MOVE O DIRETORIO ARCHIVED_WALS
#===========================================================================================================
MOVE_WALS()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Movendo o diretorio ${ARC_W} para ${ARC_WO}:" >> ${LOG} 2>&1
		if [[ -d ${ARC_WO} ]]; 
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio ja existe!" >> ${LOG} 2>&1
			mv ${ARC_WO} ${ARC_WO}_bkp_${DATA} >> ${LOG} 2>&1
			mv ${ARC_W} ${ARC_WO} >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio renomeado e movido." >> ${LOG} 2>&1		
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1			
		else
			mv ${ARC_W} ${ARC_WO} >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio movido." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		fi
	}
#===========================================================================================================
#========= RECRIA E APLICA PERMISSAOES NO DIRETORIO ARCHIVED_WALS
#===========================================================================================================
RECRIA_WALS()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Recriando o diretorio ${ARC_W}:" >> ${LOG} 2>&1
		if [[ -d ${ARC_W} ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio ja existe!" >> ${LOG} 2>&1
			mv ${ARC_W} ${ARC_W}_bkp_${DATA} >> ${LOG} 2>&1
			mkdir ${ARC_W} >> ${LOG} 2>&1
			chmod 700 ${ARC_W} >> ${LOG} 2>&1
			chmod 700 ${PG_SQL}/ >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio movido e recriado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			mkdir ${ARC_W} >> ${LOG} 2>&1
			chmod 700 ${ARC_W} >> ${LOG} 2>&1
			chmod 700 ${PG_SQL}/ >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio recriado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		fi
	}
#===========================================================================================================
#========= CHECA O STATUS DO BANCO DE DADOS
#===========================================================================================================
DB_STATUS()
	{
		${PG_SQLBIN}/pg_ctl -D ${PG_SQL} status
	}
#===========================================================================================================
#========= EFETUA A EXECUCAO DOS MODULOS
#===========================================================================================================	
EXECUTA_SCRIPT()
	{
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Inicio do processo de Pre Copia" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		DESLIGA_BANCO
		COPIA_ARQUIVO
		VERIFICA_PROCESSO
		REMOVE_CONTEUDO
		MOVE_WALS
		RECRIA_WALS
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Fim do processo de Pre Copia" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EXECUTA PROCESSO DE PRE COPIA
#===========================================================================================================
case ${HNAME} in
	linbdpje30|linbdpjeopcc1)
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "Servidor: `hostname -s | tr a-z A-Z`" >> ${LOG} 2>&1
		echo -e "Hostname: ${HOSTNAME} | (`hostname -i`)" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e >> ${LOG} 2>&1
		if [[ -e ${LOCK_PRE} ]] || [[ -e ${LOCK_POS} ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo de controle encontrado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Execucao abortada." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Favor verificar." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			exit 1;
		else
			touch ${LOCK_PRE} >> ${LOG} 2>&1
			EXECUTA_SCRIPT
			rm -f ${LOCK_PRE} >> ${LOG} 2>&1
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