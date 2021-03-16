#set -x
#!/bin/sh
#==========================================================================================================
#  Autor: Rafael Oliveira
# Resumo: Execucao automatizada de scripts nas bases POSTGRES
#==========================================================================================================

#VARIAVEL EXECUCAO
EMERGENCIA="N"  #[S|N]

#VARIAVEIS SCRIPT
CHAMADO=`echo ${1} | tr "a-z" "A-Z"`
BANCO=`echo ${2} | tr "a-z" "A-Z"`
MATRICULA=`echo ${3} | tr "a-z" "A-Z"`
BD=`echo ${BANCO} | tr "A-Z" "a-z"`
ARQUIVO=`echo ${CHAMADO} | cut -f1 -d"_"`
STR_MAT=`echo ${MATRICULA} | tr -d '[:punct:]' | tr -d '[^0-9+\-]'`
NUM_MAT=`echo -n ${MATRICULA} | tr -d '[:punct:]' | tr -d '[^A-Z+\-]' | wc -c`
SIG_MAT="P|T"
STR_CHA=`echo ${CHAMADO} | tr -d '[:punct:]' | tr -d '[^0-9+\-]'`
SIG_CHA="MDT|RS|IN"
NUM_CHA=`echo -n ${CHAMADO} | tr -d '[:punct:]' | tr -d '[^A-Z+\-]' | wc -c`
VAR_ARQ="0"
VAR_BD="0"
VAR_MAT="0"
WGET_USER=`echo ${MATRICULA} | tr "A-Z" "a-z"`
WGET_FILE="${CHAMADO}.sql"
STRING="select \'BANCO: \'||current_database() \" \";"
RED="\033[1;31m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"

#==========================================================================================================
#========= VERIFICA SE ARQUIVO EXISTE
#==========================================================================================================
FN_ARQUIVO()
	{
		if [[ -f "${CHAMADO}.sql" ]];
		then
			echo -e "${RED}\n## !! ARQUIVO ${CHAMADO}.sql JA EXISTE. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
			exit;
		else
			if [[ ${CHAMADO} =~ ['_-'] ]];
			then
				if [[ ! ${STR_CHA} =~ ^($SIG_CHA)$  ]] || [[ ${NUM_CHA} != "9" ]];
				then
					echo -e "${RED}\n## !!   ${CHAMADO} INCORRETO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
				else
					VAR_ARQ="1"
					break;
				fi
			elif [[ ${CHAMADO} =~ ['!@#$%^&*()+.,='] ]];
			then
				echo -e "${RED}\n## !! CHAMADO ${CHAMADO} INCORRETO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
			else
				if [[ ! ${STR_CHA} =~ ^($SIG_CHA)$  ]] && [[ ${NUM_CHA} != "7" ]];
				then
					echo -e "${RED}\n## !! CHAMADO ${CHAMADO} INCORRETO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
				else
					VAR_ARQ="1"
					break;
				fi
			fi
		fi
	}
#==========================================================================================================
#========= VERIFICA SE O BANCO ESTA CORRETO
#==========================================================================================================
FN_BANCO()
	{
		if [[ ${BANCO} != "PJE" ]] && [[ ${BANCO} != "PJERECURSAL" ]] && [[ ${BANCO} != "PJEDOCUMENTOS" ]] && [[ ${BANCO} != "BINARIOS" ]];
		then
			echo -e "${RED}\n## !! BANCO ${BANCO} INCORRETO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
		else
			VAR_BD="1"
			break;
		fi
	}
#==========================================================================================================
#========= VERIFICA SE A MATRICULA ESTA CORRETA
#==========================================================================================================
FN_MATRICULA()
	{
		if [[ ! ${STR_MAT} =~ ^($SIG_MAT)$  ]] || [[ ${NUM_MAT} != "7" ]];
		then
			echo -e "${RED}\n## !! MATRICULA ${MATRICULA} INCORRETA. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
		else
			VAR_MAT="1"
			break;
		fi
	}
#==========================================================================================================
#========= VERIFICA E CRIA O ARQUIVO .SQL
#==========================================================================================================
FN_CRIA()
	{
		case ${EMERGENCIA} in
			N)
				echo -e "\n## COLE O LINK DO CHAMADO ${ARQUIVO} A SER EXECUTADO ##\n"
				while read WGET_ADDR
				do
					wget -S -o "${WGET_USER}".tmp --no-check-certificate --http-user="${WGET_USER}" --ask-password --spider "${WGET_ADDR}" \
					&& echo -e "\n## REVISAO ##"; \
					sed -nr 's/^  ETag:([^.]*).*/\1/p' ${WGET_USER}.tmp \
					| awk -F// '{$NF=""} 1' \
					| sed 's/.*"//'
				break;
				done
				if [[ `grep -F "ETag" ${WGET_USER}.tmp` ]];
				then
					echo -e "\n## A REVISAO DO ARQUIVO ESTA CORRETA [S/N]? ##"
					while read WGET_SVN
					do
						case ${WGET_SVN} in
							SIM|sim|S|s)
								echo -e ""
								wget -q -S -O "${WGET_FILE}" -o "${WGET_USER}".tmp --no-check-certificate --http-user="${WGET_USER}" --ask-password "${WGET_ADDR}"
								if [[ ${VAR_ARQ} = "1" ]] && [[ `grep -F "ETag" ${WGET_USER}.tmp` ]];
								then
									if [[ ! -f "${CHAMADO}.sql" ]];
									then
										echo -e "${RED}\n## !! ARQUIVO ${CHAMADO}.sql NAO FOI CRIADO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
										exit 1;
									else
										if [[ -s ${CHAMADO}.sql ]];
										then
											echo -e "\n## ARQUIVO ${CHAMADO}.sql CRIADO ##"
											rm -f ${WGET_USER}.tmp
										else
											echo -e "${RED}\n## !! ARQUIVO ${CHAMADO}.sql ESTA VAZIO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
											exit 1;
										fi
									fi
								else
									echo -e "${RED}\n## !! NAO FOI POSSIVEL OBTER OS DADOS DO ARQUIVO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
									exit;
								fi
								break;
								;;
							NAO|nao|N|n)
								echo -e "${RED}\n## !! EXECUCAO CANCELADA !! ##\n${NOCOLOR}"
								rm -f ${WGET_USER}.tmp
								exit 1;
								;;
							*)
								echo -e "${GREEN}\n## !! DIGITE [S]IM OU [N]AO !! ##${NOCOLOR}"
								;;
						esac
					break;
					done
				else
					echo -e "${RED}\n## !! NAO FOI POSSIVEL OBTER OS DADOS DO ARQUIVO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
					exit 1;
				fi
				;;
			S)
				echo -e "\n## COLE O SCRIPT DO CHAMADO ${CHAMADO} A SER EXECUTADO ##\n"
				FN_PAUSA "## [ENTER] PARA CRIAR O ARQUIVO ${CHAMADO}.sql ##"
				if [[ ${VAR_ARQ} = "1" ]];
				then
					vi ${CHAMADO}.sql
					if [[ ! -f "${CHAMADO}.sql" ]];
					then
						echo -e "${RED}\n## !! ARQUIVO ${CHAMADO}.sql NAO FOI CRIADO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
						exit 1;
					else
						if [[ -s ${CHAMADO}.sql ]];
						then
							echo -e "\n## ARQUIVO ${CHAMADO}.sql CRIADO ##"
						else
							echo -e "${RED}\n## !! ARQUIVO ${CHAMADO}.sql ESTA VAZIO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
							exit 1;
						fi
					fi
				else
					exit;
				fi
				;;
			*)
				echo -e "${RED}\n## !! VALOR DA VARIAVEL "EMERGENCIA" ESTA INCORRETO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
				exit 1;
				;;
		esac
	}
#==========================================================================================================
#========= INSERE O SELECT NO ARQUIVO .SQL
#==========================================================================================================
FN_INSERE()
	{
		sed -i '1i select '\''BANCO: '\''||current_database() " ";' ${CHAMADO}.sql
		if [[ `grep -q "${STRING}" "${CHAMADO}.sql"` != "0" ]]; 
		then
			echo -e "\n## COMANDO SELECT INSERIDO EM ${CHAMADO}.sql ##"
		else
			echo -e "${RED}\n## !! COMANDO SELECT NAO INSERIDO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
			exit;
		fi	
	}
#==========================================================================================================
#========= ADICIONA DADOS AO ARQUIVO .LOG
#==========================================================================================================
FN_ADICIONA()
	{
		sed -i '1i -----| DADOS DA EXECUCAO |-----' ${CHAMADO}.log
		sed -i '2i \ ' ${CHAMADO}.log
		sed -i '3i \ DBA: '$MATRICULA'' ${CHAMADO}.log
		sed -i '4d;5d;7d' ${CHAMADO}.log
		sed -i '6i ------| LOG DA EXECUCAO |------' ${CHAMADO}.log
		sed -i '7i \ ' ${CHAMADO}.log
	}
#==========================================================================================================
#========= CONVERTE E MOVE O SCRIPT
#==========================================================================================================
FN_CONVERTE()
	{
		iconv -c -f utf-8 -t iso-8859-1 ${CHAMADO}.sql > ${CHAMADO}_iso.sql
		if [[ ${?} = "0" ]];
		then
			mv ${CHAMADO}_iso.sql ${CHAMADO}.sql
			echo -e "\n## CONVERSAO DE ${CHAMADO}.sql EFETUADA ##"
		else
			echo -e "${RED}\n## !! ARQUIVO ${CHAMADO}.sql NAO CONVERTIDO. FAVOR VERIFICAR !! ##\n${NOCOLOR}"
			exit;
		fi
	}
#==========================================================================================================
#========= CHECA ERROS
#==========================================================================================================
FN_CHECAGEM()
        {
                grep --line-buffered -wi 'ERROR\|ERR\|could not connect to server' ${CHAMADO}.log
        }
#==========================================================================================================
#========= CONVERTE DATA
#==========================================================================================================
FN_DATA()
	{
		DURACAO=$(date -d @$((`date -d "$FIM" +%s` - `date -d "$INICIO" +%s`)) -u +%H:%M:%S)
		echo -e "#############################################################################################"
		echo -e "## INICIO: ${INICIO}"
		echo -e "## FIM: ${FIM}"
		echo -e "## DURACAO: ${DURACAO}"
		echo -e "#############################################################################################"
		echo -e ""
	}
#==========================================================================================================
#========= CONTROLE DE PAUSA
#==========================================================================================================
FN_PAUSA()
	{
		read -p "$*"
	}
#==========================================================================================================
#========= EXECUTA O COMANDO NO BANCO
#==========================================================================================================
FN_EXECUTA()
	{
		echo -e "\n## DESEJA EXECUTAR ${CHAMADO}.sql [S/N]? ##"
		while read EXC
		do
			case ${EXC} in
				SIM|S|sim|s)
					echo -e ""
					FN_PAUSA "## [ENTER] PARA EXECUTAR ${CHAMADO}.sql ##"
					INICIO=`date +"%Y/%m/%d %H:%M:%S"`
					psql -v ON_ERROR_STOP=on -U postgres -p 5432 -w -d ${BD} < ${CHAMADO}.sql >> ${CHAMADO}.log 2>&1
					FIM=`date +"%Y/%m/%d %H:%M:%S"`
					CHECAGEM=$(FN_CHECAGEM)
					if [[ $? = "0" || $? = "1" ]] && [[ -z ${CHECAGEM} ]];
					then
						echo -e ""
						echo -e "${BLUE}#############################################################################################"
						echo -e "## EXECUCAO DO ARQUIVO ${CHAMADO}.sql PELO DBA ${MATRICULA} NO BANCO ${BANCO}: SUCESSO"
						echo -e "##"
						echo -e "## IMPORTANTE: EXTRAIR E ANEXAR O LOG ${CHAMADO}.log NO CHAMADO ${ARQUIVO}"
						echo -e "#############################################################################################${NOCOLOR}"
						echo -e ""
					else
						echo -e ""
						echo -e "${RED}#############################################################################################"
						echo -e "## EXECUCAO DO ARQUIVO ${CHAMADO}.sql PELO DBA ${MATRICULA} NO BANCO ${BANCO}: ERRO"
						echo -e "#############################################################################################${NOCOLOR}"
						echo -e ""
						if [[ ! -z ${CHECAGEM} ]];
						then
							echo -e "${RED}#############################################################################################"
							echo -e "${CHECAGEM}"
							echo -e "#############################################################################################${NOCOLOR}"
							echo -e ""
						else
							echo -e "${RED}#############################################################################################"
							echo -e "## VERIFIQUE O LOG ${CHAMADO}.log PARA MAIS INFORMACOES"
							echo -e "#############################################################################################${NOCOLOR}"
							echo -e ""
						fi
					fi
					break;
					;;
				NAO|N|nao|n)
					echo -e "${RED}\n## !! EXECUCAO CANCELADA !! ##\n${NOCOLOR}"
					exit 1;
					;;
				*)
					echo -e "${GREEN}\n## !! DIGITE [S]IM OU [N]AO !! ##${NOCOLOR}"
					;;
			esac
		done
	}
#==========================================================================================================
#========= CONTROLE DE EXECUCAO
#==========================================================================================================
clear
if [ `echo $#` -lt "3" ]
then
	echo -e "${RED}\n## !! FALTA DE PARAMETROS !! ##\n${NOCOLOR}"
	echo -e "${RED}## !! EX: exec_chamados_postgres.sh <CHAMADO [(RS|IN|MDT)(#######|#######_#)]> <BANCO [PJE|PJERECURSAL]> <MATRICULA [(P|T)(#######)]> !! ##\n${NOCOLOR}"
	exit 3
else
	FN_ARQUIVO
	FN_BANCO
	FN_MATRICULA
	if [[ ${VAR_ARQ} != "0" ]] && [[ ${VAR_BD} != "0" ]] && [[ ${VAR_MAT} != "0" ]];
	then
		echo -e ""
		echo -e "#############################################################################################"
		echo -e "## CHAMADO: ${ARQUIVO}"
		echo -e "## BANCO: ${BANCO}"
		echo -e "## DBA: ${MATRICULA}"
		echo -e "#############################################################################################"
		echo -e ""
		echo -e "## AS INFORMACOES ACIMA ESTAO CORRETAS [S/N]? ##"
		while read OPCAO
		do
			case ${OPCAO}
			in
				SIM|S|sim|s)
					FN_CRIA
					FN_INSERE
					FN_CONVERTE
					FN_EXECUTA
					FN_DATA
					FN_ADICIONA
					break;
					;;
				NAO|N|nao|n)
					echo -e "${RED}\n## !! EXECUCAO CANCELADA !! ##\n${NOCOLOR}"
					exit 1;
					;;
				*)
					echo -e "${GREEN}\n## !! DIGITE [S]IM OU [N]AO !! ##${NOCOLOR}"
					;;
			esac
		done
	fi
fi