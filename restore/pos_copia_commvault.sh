#set -x
#!/bin/sh
#===========================================================================================================
#  Autor: Rafael Oliveira
# Resumo: Realiza Pos Copia Banco PJE-SUP
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
SLP='10'
DESTINO=`hostname -i`
COUNT='1'
LOG=${SCP_DIR}/log/${DATA}_POS_COPIA_PJE-SUP.log

#===========================================================================================================
#========= REMOVE O DIRETORIO ARCHIVED_WALS_OLD
#===========================================================================================================
REMOVE_WALS_OLD()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Apagando diretorio ${ARC_WO}:" >> ${LOG} 2>&1
		rm -rf ${ARC_WO} >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Diretorio apagado." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= MOVE OS ARQUIVOS PG_HBA.CONF E POSTGRESQL.CONF PARA PG_HBA.CONF_BKP E POSTGRESQL.CONF_BKP
#===========================================================================================================
MOVE_ARQUIVO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Movendo os arquivos pg_hba.conf e postgresql.conf:" >> ${LOG} 2>&1
		if [[ -e ${PG_SQL}/pg_hba.conf && ${PG_SQL}/postgresql.conf ]];
		then
			mv ${PG_SQL}/pg_hba.conf ${PG_BKP}/pg_hba.conf_bkp >> ${LOG} 2>&1
			mv ${PG_SQL}/postgresql.conf ${PG_BKP}/postgresql.conf_bkp >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos movidos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos nao existem." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= COPIA OS ARQUIVOS PG_HBA.CONF E POSTGRESQL.CONF PARA AS CONFIGURAÇÕES DO SERVIDOR SUP
#===========================================================================================================
COPIA_ARQUIVO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Copiando os arquivos pg_hba.conf e postgresql.conf:" >> ${LOG} 2>&1
		cp ${PG_H_REC} ${PG_SQL}/pg_hba.conf >> ${LOG} 2>&1
		cp ${PG_P_REC} ${PG_SQL}/postgresql.conf >> ${LOG} 2>&1
		if [[ ${?} = "0" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivos copiados." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Erro na copia dos arquivos." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= INICIA O BANCO DE DADOS
#===========================================================================================================
INICIA_BANCO()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Iniciando o Banco de Dados:" >> ${LOG} 2>&1
		STR=$(DB_STATUS)
		if [[ ${STR} = "pg_ctl: no server running" ]];
		then
			${PG_SQLBIN}/pg_ctl -D ${PG_SQL} start >> ${LOG} 2>&1
			STR=$(DB_STATUS)
			while [[ ${STR} = "pg_ctl: server did not start in time" ]];
			do
				STR=$(DB_STATUS)
				${PG_SQLBIN}/pg_ctl -D ${PG_SQL} start >> ${LOG} 2>&1
				COUNT=`expr ${COUNT} + 1`
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] "${COUNT}"a tentativa de iniciar o banco." >> ${LOG} 2>&1
				sleep 1m;
			done
			if [[ ${STR} =~ "pg_ctl: server is running" ]];
			then
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco iniciado com sucesso." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na inicializacao do banco." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				rm -f ${LOCK_POS} >> ${LOG} 2>&1
				exit 1;
			fi
		elif [[ ${STR} =~ "pg_ctl: server is running" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Banco ja se encontra ligado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema na inicializacao do banco." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= VERIFICA O PROCESSO DOS ARCHIVED LOGS
#===========================================================================================================
VERIFICA_ARCHIVE()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Verificando o processo de recovery:" >> ${LOG} 2>&1
		OUT_ARC=$(VERIFICA_OUTPUT)
		if [[ ${OUT_ARC} =~ "t" ]];
		then
			OUT_ARC=$(VERIFICA_OUTPUT)
			while [[ ${OUT_ARC} =~ "t" ]];
			do
				OUT_ARC=${VERIFICA_OUTPUT}
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Recovery em execucao..." >> ${LOG} 2>&1
				sleep ${SLP}m >> ${LOG} 2>&1
			done
			if [[ ${OUT_ARC} =~ "f" ]];
			then
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Recovery finalizado" >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Verificar o status do banco." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				rm -f ${LOCK_POS} >> ${LOG} 2>&1
				exit 1;
			fi
		else
			if [[ ${OUT_ARC} =~ "f" ]];
			then
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Recovery finalizado" >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			else
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Verificar o status do banco." >> ${LOG} 2>&1
				echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
				rm -f ${LOCK_POS} >> ${LOG} 2>&1
				exit 1;
			fi
		fi
	}
#===========================================================================================================
#========= PARA O BANCO DE DADOS
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
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Problema no desligamento do banco." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_PRE} >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= RENOMEIA O ARQUIVO RECOVERY.CONF PARA RECOVERY.DONE
#===========================================================================================================
RENOMEIA_RECOVERY()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Renomeando o arquivo recovery.conf para recovery.done:" >> ${LOG} 2>&1
		if [[ -e ${PG_SQL}/recovery.conf ]];
		then
			mv ${PG_SQL}/recovery.conf ${PG_SQL}/recovery.done >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo renomeado." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Arquivo nao existe." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		fi
	}
#===========================================================================================================
#========= INICIA A EXECUÇÃO DOS SCRIPTS POS COPIA
#===========================================================================================================
SCRIPTS_POS()
	{
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Executando os scripts de pos copia:" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/script_pos_copia_sup.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pjerecursal -e -w -f ${SCP_BASE}/script_pos_copia_sup.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/script_diario_pjesup.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pjerecursal -e -w -f ${SCP_BASE}/script_diario_pjesuprecursal.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d binarios -e -w -f ${SCP_BASE}/altera_interface_acesso_s3_sup.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/RS1047671_pje_nao_apagar.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pjerecursal -e -w -f ${SCP_BASE}/RS1047671_pjerecursal_nao_apagar.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/migrations.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/cria_usuario_schema_pre_prd.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/script_appdynamics_sup.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d binarios -e -w -f ${SCP_BASE}/script_appdynamics_sup.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pje -e -w -f ${SCP_BASE}/UPDATE_tb_endereco_wsdl_NAO_APAGAR.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		${PG_SQLBIN}/psql -h ${DESTINO} -U postgres -p 5432 -d pjerecursal -e -w -f ${SCP_BASE}/UPDATE_tb_endereco_wsdl_NAO_APAGAR.sql >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		if [[ "${?}" = "0" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Scripts executados." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Erro na execucao dos scripts." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
			exit 1;
		fi
	}
#===========================================================================================================
#========= INICIA O VACUUMDB
#===========================================================================================================
INICIA_VACUUMDB()
	{
		echo -e "[`date +%Y-%m-%d_%H:%M:%S`] Executando o analyze para coletar estatisticas:" >> ${LOG} 2>&1
		${PG_SQLBIN}/vacuumdb -h ${DESTINO} -U postgres -a -Z -p 5432 -j 5 >> ${LOG} 2>&1
		SAIDA=$?
		if [[ "${SAIDA}" != "0" ]];
		then
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Erro na execucao do vacuumdb." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] CODIGO=${SAIDA}." >> ${LOG} 2>&1
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
			exit 1;
		else
			echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Processo executado." >> ${LOG} 2>&1
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
#========= VERIFICA O STATUS DO BANCO
#===========================================================================================================
VERIFICA_OUTPUT()
	{
		psql -U postgres -p 5432 -c 'select pg_is_in_recovery();' | sed 's/^.* //' | sed 's/^.*-//' | sed 's/r.*//' | sed '/^[[:space:]]*$/d'
	}
#===========================================================================================================
#========= EFETUA A EXECUCAO DOS MODULOS
#===========================================================================================================	
EXECUTA_SCRIPT()
	{
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Inicio do processo de Pos Copia" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
		MOVE_ARQUIVO
		COPIA_ARQUIVO
		INICIA_BANCO
		VERIFICA_ARCHIVE
		DESLIGA_BANCO
		RENOMEIA_RECOVERY
		INICIA_BANCO
		SCRIPTS_POS
		INICIA_VACUUMDB
		REMOVE_WALS_OLD
		echo -e "============================================================================================" >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] Fim do processo de Pos Copia" >> ${LOG} 2>&1
		echo -e "============================================================================================" >> ${LOG} 2>&1
	}
#===========================================================================================================
#========= EXECUTA PROCESSO DE POS COPIA
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
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
			exit 1;
		else
			touch ${LOCK_POS} >> ${LOG} 2>&1
			EXECUTA_SCRIPT
			rm -f ${LOCK_POS} >> ${LOG} 2>&1
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
		rm -f ${LOCK_POS} >> ${LOG} 2>&1
		exit 4;
		;;
	*)
		echo -e "Servidor `hostname -s | tr a-z A-Z` invalido." >> ${LOG} 2>&1
		echo -e "Execucao abortada." >> ${LOG} 2>&1
		echo -e "[`date +"%Y-%m-%d %H:%M:%S"`] ==============================================" >> ${LOG} 2>&1
		rm -f ${LOCK_POS} >> ${LOG} 2>&1
		exit 5;
		;;
esac