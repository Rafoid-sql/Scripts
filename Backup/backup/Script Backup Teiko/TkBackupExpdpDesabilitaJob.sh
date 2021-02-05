#set -x
#!/bin/ksh
#######################################################
# Autor: Jailson Sc2011                               #
# Email: jailson.schhmoeller                          #
# Data.: 16/02/@teiko.com.br                          #
#                                                     #
# Alterado por: Gustavo Mario Daros - Teiko           #
# Alterado em : 20/04/2011                            #
# Motivo      : Gerar evento para o monitoramento a   #
#               nivel de backup e nao a cada owner    #
# Alterado por: Rafael Stoever - Teiko                #
# Alterado em : 20/09/2012                            #
# Motivo      : Controle de erros ORA-01466 contra a  #
#               a tabela teikobkp.tk_bkp_exclui_tabela#
#               ignorando o erro no monitoramento se  #
# Alterado por: Rafael Stoever - Teiko                #
# Alterado em : 06/12/2012                            #
# Motivo      : Checagem do arquivo de log qdo houver #
#               um fatal erro o backup eh abortado e  #
#               deve ser enviado um alert de error.   #
# Alterado por: Joao Vitor - Teiko                    #
# Alterado em : 01/02/2013                            #
# Motivo      : Controle dos owner ignorado sera      #
#               realizado pela tabela TK_BK_OWNER     #
# Alterado por: Joao Vitor - Teiko                    #
# Alterado em : 20/05/2014                            #
# Motivo      : Controle de verificação do errp       #
#               Caso seja ignorado uma tabela da      #
#               verificaçao a mesma nao alertar se    #
#               ocorrer erro nela                     #
# Alterado por: Luiz/Jeferson - Teiko                 #
# Alterado em : 23/07/2015                            #
# Motivo      : Controle de verificação do erro       #
#               Adicionado parametro IDIOMA para      #
#               verificar os erros de tabelas         #
#######################################################
# Descricao:                                          #
#######################################################
# Descricao: Rotina via Expdp (datapump) por:         #
#    Opcoes: owner -> Faz backup por owner.           #
#            full  -> Faz backup full da base.        #
#   Exemplo:sh TkBackupExpdp.sh $ORACLE_SID owner 3 S #
#######################################################

DISPLAY(){
echo "[`date '+%d/%m/%Y %T'`] $*" >> $ARQ_LOG_GERAL
}



EVENTO(){
# Funcao que efetua o envio de evento para o monitoramento
  DESCRICAO_MENSAGEM="$1"
  SEVERIDADE_MENSAGEM=$2
  ANEXO_MENSAGEM=$3

  if [ ${BKP_MONITORADO} = "S" ]
  then
    if [ ${SEVERIDADE_MENSAGEM} = 2 ]
    then
          sh ${FAROL} --alvo=${INSTANCE} --aplicacao=Backup_Teiko --objeto=expdp_${INSTANCE} --severidade=${SEVERIDADE_MENSAGEM} --im=expdp_${INSTANCE} --anexo=${ANEXO_MENSAGEM} --mensagem=${DESCRICAO_MENSAGEM}
      #echo "Log em Anexo" | mutt -s "${DESCRICAO_MENSAGEM}" -a ${ANEXO_MENSAGEM} ${EMAIL}
        fi
    if [ ${SEVERIDADE_MENSAGEM} = 0 ]
    then
      sh ${FAROL} --alvo=${INSTANCE} --aplicacao=Backup_Teiko --objeto=expdp_${INSTANCE} --severidade=${SEVERIDADE_MENSAGEM} --im=expdp_${INSTANCE} --mensagem=${DESCRICAO_MENSAGEM}
      #echo "Log em Anexo" | mutt -s "${DESCRICAO_MENSAGEM}" -a ${ANEXO_MENSAGEM} ${EMAIL}
        fi
  fi
}

EVENTO_COPIA(){
# Funcao que efetua o envio de evento para o monitoramento
  DESCRICAO_MENSAGEM="$1"
  SEVERIDADE_MENSAGEM=$2
  ANEXO_MENSAGEM=$3

  if [ ${BKP_MONITORADO} = "S" ]
  then
    if [ ${SEVERIDADE_MENSAGEM} = 2 ]
    then
          ERRO_COPIA=1
      sh ${FAROL} --alvo=${INSTANCE} --aplicacao=Backup_Teiko --objeto=copia_expdp_${INSTANCE} --severidade=${SEVERIDADE_MENSAGEM} --im=copia_expdp_${INSTANCE} --anexo=${ANEXO_MENSAGEM} --mensagem=${DESCRICAO_MENSAGEM}
      echo "Log em Anexo" | mutt -s "${DESCRICAO_MENSAGEM}" -a ${ANEXO_MENSAGEM} ${EMAIL}
        fi
    if [ ${SEVERIDADE_MENSAGEM} = 0 ]
    then
      sh ${FAROL} --alvo=${INSTANCE} --aplicacao=Backup_Teiko --objeto=copia_expdp_${INSTANCE} --severidade=${SEVERIDADE_MENSAGEM} --im=copia_expdp_${INSTANCE} --mensagem=${DESCRICAO_MENSAGEM}
      echo "Log em Anexo" | mutt -s "${DESCRICAO_MENSAGEM}" -a ${ANEXO_MENSAGEM} ${EMAIL}
        fi
  fi
}

GERA_OWNER(){
# Funcao para Gerar Lista de todos os owner da base com tabelas
# Criar a tabela TK_BKP_OWNER e inserir nela os owner que serao Ignorados do BACKUP
${ORACLE_HOME}/bin/sqlplus -s teikobkp/bkpokiet@srvivlmbd02:1521/treina 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${ARQ_OWNER}
SELECT
                OWNER
           FROM
                DBA_OBJECTS
           HAVING
                COUNT(*) > 0 AND UPPER(OWNER) NOT IN (SELECT
                UPPER(NOMOWN)
           FROM
               TK_BKP_OWNER )
           GROUP BY
                OWNER;
spool off;
quit
EOF

if [ "$?" = "0" ]
then
  DISPLAY "Gerando a Lista dos Usuarios..: OK"
  DISPLAY "==============================="
  DISPLAY "==============================="
else
  DISPLAY "Gerando Lista de Usuario......: ERRO"

  EVENTO "Erro na Geracao da Lista de Usuarios do Backup via DATAPUMP" 2 ${ARQ_LOG_GERAL}

fi

}

CAPTURA_SCN(){
#Funcao para capturar scn para gerar backup consistente
${ORACLE_HOME}/bin/sqlplus -s teikobkp/bkpokiet@srvivlmbd02:1521/treina 2>&1 <<EOF
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

if [ "$?" = "0" ]
then
  DISPLAY "Capturado SCN atual da base de dados..: OK"
  DISPLAY "==============================="
  DISPLAY "==============================="
else
  DISPLAY "Falha ao pegar SCN atual......: ERRO"

  EVENTO "Erro no SELECT do SCN do Banco de Dados" 2 ${ARQ_LOG_GERAL}

fi

}

GERAR_LST_ORA(){
${ORACLE_HOME}/bin/sqlplus -s teikobkp/bkpokiet@srvivlmbd02:1521/treina 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${DIR_TMP}/usuario.txt
SELECT distinct(owner) from TK_BKP_EXCLUI_TABELA;
spool off;
spool ${DIR_TMP}/tk_bkp_exclui_tabela.txt
select '"'||owner||'"."'||tabela||'"' from tk_bkp_exclui_tabela group by owner,tabela;
spool off;
quit
EOF

achou=0
if [ "$(cat ${TMP_FILE2} | grep "ORA-31693")" != "" ]; then
cat ${TMP_FILE2} | grep "ORA-31693" > ${ERRO}
        if [ "${TIPO}" = "OWNER" ]; then
                awk '{print '${IDIOMA}'}' ${ERRO} > ${LOG_COMPARA}
                for i in `cat ${LOG_COMPARA}`
                do
                        AC=`cat ${USER_TABLES} | grep -c ${i}`
                        if [ ${AC} -ne 1 ]; then
                                echo ${i} >> ${LOG_COMPARA}.erro
                                achou=1
                        fi
                done
        elif [ "${TIPO}" = "FULL" ]; then
                awk '{print '${IDIOMA}'}' ${ERRO} > ${LOG_COMPARA}
                for i in `cat ${LOG_COMPARA}`
                do
                        AC=`cat ${USER_TABLES} | grep -c ${i}`
                        if [ ${AC} -ne 1 ]; then
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
        FIM_EXPORT=ERRO
fi
}


DESABILITA_JOB(){
#FUNCAO PARA DESABILITAR JOB

${ORACLE_HOME}/bin/sqlplus -s teikobkp/bkpokiet@srvivlmbd02:1521/treina 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
ALTER SYSTEM SET job_queue_processes=0 SCOPE=BOTH;
spool off;
quit
EOF

if [ "$?" = "0" ]
then
  DISPLAY "DESABILITA JOB_QUEUE.......: OK"
  DISPLAY "==============================="
  DISPLAY "==============================="
else
  DISPLAY "Falha para desabilitar JOB ......: ERRO"

  EVENTO "Erro para desabilitar JOB" 2 ${ARQ_LOG_GERAL}

fi
}

HABILITA_JOB(){
#FUNCAO PARA habilitar JOB

${ORACLE_HOME}/bin/sqlplus -s teikobkp/bkpokiet@srvivlmbd02:1521/treina 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
ALTER SYSTEM SET job_queue_processes=10 SCOPE=BOTH;
spool off;
quit
EOF

if [ "$?" = "0" ]
then
  DISPLAY "HABILITA JOB_QUEUE.......: OK"
  DISPLAY "==============================="
  DISPLAY "==============================="
else
  DISPLAY "Falha para habilitar JOB ......: ERRO"

  EVENTO "Erro para habilitar JOB" 2 ${ARQ_LOG_GERAL}

fi
}

#REMOTO (){
 #      echo "Inciando copia remota do Backup DataPump" >> ${ARQ_LOG_GERAL}
       #/sbin/mount.cifs //192.168.0.7/backup /mnt/logico -o username=${user_remoto},password=${senha_remoto} >> ${ARQ_LOG_GERAL}
  #     ret=$?
  #     if [ "${ret}" != "0" ]
  #     then
  #        echo "Erro mount filesystem remoto do Backup" >> ${ARQ_LOG_GERAL}
 #         EVENTO_COPIA "Erro mount filesystem remoto do Backup" 2 ${ARQ_LOG_GERAL}
 #      else
 #     #    find /mnt/logico/logico/*.dmp.gz -mtime +2 -print -exec rm -f {} \; > /dev/null 2>&1
 #     #    find ${DIR_DMP} -maxdepth 1 -name '*.dmp.gz*'  -exec cp -uv {} /mnt/logico/logico \;
 #         ret=$?
 #         if [ "${ret}" != "0" ]
 #         then
 #            echo " Erro copia remota do Backup DataPump" >> ${ARQ_LOG_GERAL}
 #            EVENTO_COPIA "Erro copia remota do Backup DataPump" 2 ${ARQ_LOG_GERAL}
 #         else
 #            echo " Sucesso copia remota do Backup" >> ${ARQ_LOG_GERAL}
 #            EVENTO_COPIA "Sucesso na copia remota do Backup" 0 ${ARQ_LOG_GERAL}
 #         fi
 #         #/bin/umount /mnt/logico > /dev/null 2>&1
 #      fi
#}

EXPORT_OWNER(){
# Gera A lista de Usuarios com tabelas
GERA_OWNER
# executa Expdp
for USUARIO in `cat ${ARQ_OWNER}`
do

  #Captura SCN da base de dados
  CAPTURA_SCN
  SCN=`cat ${SCN_ATUAL}`
  ARQ_LOG=${INSTANCE}.${USUARIO}.`date +%Y%m%d%H`
  export TMP_FILE2=${DIR_TMP}/${INSTANCE}.${USUARIO}.`date +%Y%m%d%H`.tmp
  ARQ_DMP=${INSTANCE}.${USUARIO}%U.`date +%Y%m%d%H`.dmp

  DISPLAY "Expdp do UsuÃ¡o..............: ${USUARIO}"
  DISPLAY "Inicio........................: `date '+%d/%m/%Y %T'`"

  expdp userid=teikobkp/bkpokiet@srvivlmbd02:1521/treina DIRECTORY=DATA_PUMP_TREINABKP FLASHBACK_SCN=$SCN VERSION=${ORACLE_VERSION} SCHEMAS='\"'${USUARIO}'\"' DUMPFILE=${ARQ_DMP} logfile=${ARQ_LOG} filesize=5000M < /dev/null 2>${TMP_FILE2}

#Verifica se o backup foi executado com sucesso
if [ -e ${DIR_DMP}/${ARQ_LOG} ]
then
        if [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "${PROC_SUCESS}")" == "" ] || [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "ORA-" -e "EXP-")" != "" ];
        then
                GERAR_LST_ORA
        else
                FIM_EXPORT=OK
        fi
else
  FIM_EXPORT=ERRO
fi

gzip ${DIR_DMP}/*.dmp

#Verifica se a compactacao dos dumps foi efetuada com sucesso
if [ "$?" = "0" ]
then
  FIM_COMPACTACAO=OK
else
  FIM_COMPACTACAO=ERRO
fi


#Verifica se todo o procedimento do backup de cada owner foi efetuado com sucesso
if [ "${FIM_EXPORT}" = "OK" ] && [ "${FIM_COMPACTACAO}" = "OK" ]
then
  mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.ok
  export STATUS=OK
  DISPLAY "Fim...........................: `date '+%d/%m/%Y %T'`"
  DISPLAY "Log Execucao..................: ${DIR_LOG}/${ARQ_LOG}.ok"
  DISPLAY "Status........................: ${STATUS}"
else
  ERROR_COUNT=`expr $ERROR_COUNT + 1`
  export STATUS=ERRO
  DISPLAY "Fim...........................: `date '+%d/%m/%Y %T'`"

  if [ "${FIM_EXPORT}" != "OK" ]
  then
    DISPLAY "Export........................: ${FIM_EXPORT}"
  fi

  if [ "${FIM_COMPACTACAO}" != "OK" ]
  then
    DISPLAY "Compactacao...................: ${FIM_COMPACTACAO}"
  fi

  mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.erro
  DISPLAY "Log Execucao..................: ${DIR_LOG}/${ARQ_LOG}.erro"
  DISPLAY "Status........................: ${STATUS}"

fi

  DISPLAY "==============================="

done


#Gera o resumo geral do backup

if [ "${ERROR_COUNT}" = "0" ]
then
  STATUS_GERAL=OK
else
  STATUS_GERAL=ERRO
fi

FIM_BACKUP="`date '+%d/%m/%Y %T'`"

DISPLAY "==============================="
DISPLAY "==============================="
DISPLAY "====R E S U M O   G E R A L===="
DISPLAY "Inicio do Backup..............: ${INICIO_BACKUP}"
DISPLAY "Fim do Backup.................: ${FIM_BACKUP}"

if [ "${STATUS_GERAL}" != "OK" ]
then
  DISPLAY "Owners com Erro...............: ${ERROR_COUNT}"
fi

DISPLAY "Log da Execucao do Backup.....: ${ARQ_LOG_GERAL}"
DISPLAY "Status do Backup..............: ${STATUS_GERAL}"
DISPLAY "==============================="
DISPLAY "==============================="


if [ "${STATUS_GERAL}" = "OK" ]
then
    EVENTO "Sucesso na execucao do backup OWNER via DATAPUMP" 0
else
    EVENTO "ERRO na execucao do backup OWNER via DATAPUMP" 2 ${ARQ_LOG_GERAL}
fi



}

EXPORT_FULL(){
  # Captura SCN da base de dados
  CAPTURA_SCN
  SCN=`cat ${SCN_ATUAL}`
  ARQ_LOG=${INSTANCE}.FULL.`date +%Y%m%d%H`.log
  ARQ_DMP=${INSTANCE}.FULL%U.`date +%Y%m%d%H`.dmp

  DISPLAY "-------------------------------"
  DISPLAY "-------------------------------"
  DISPLAY "-----N O V O   B A C K U P-----"
  DISPLAY "-------------------------------"
  DISPLAY "-------------------------------"
  DISPLAY "Inicio do Backup Expdp.......: ${PARAMETRO_LINHA}"
  DISPLAY "..............................: Inicio"

  expdp userid=teikobkp/bkpokiet@srvivlmbd02:1521/treina DIRECTORY=DATA_PUMP_TREINABKP FLASHBACK_SCN=$SCN VERSION=${ORACLE_VERSION} FULL=Y DUMPFILE=${ARQ_DMP} logfile=${ARQ_LOG} filesize=5000M < /dev/null 2>${TMP_FILE2}

  if [ -e ${DIR_DMP}/${ARQ_LOG} ]
then
        if [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "$PROC_SUCESS")" == "" ] || [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "ORA-" -e "EXP-")" != "" ];
        then
                GERAR_LST_ORA
                else
                FIM_EXPORT=OK
                fi
else
  FIM_EXPORT=ERRO
fi

if [ "${FIM_EXPORT}" = "OK" ]
then
DISPLAY "..............................: Backup executado com sucesso"
else
DISPLAY "..............................: Backup executado com erro"
fi

gzip ${DIR_DMP}/*.dmp

#Verifica se a compactacao dos dumps foi efetuada com sucesso
if [ "$?" = "0" ]
then
  FIM_COMPACTACAO=OK
  DISPLAY "..............................: Compactacao executado com sucesso"
else
  FIM_COMPACTACAO=ERRO
  DISPLAY "..............................: Compactacao executado com erro"
fi
if [ "${FIM_EXPORT}" = "OK" ] && [ "${FIM_COMPACTACAO}" = "OK" ]
then
  mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.ok
  echo "--> Finalizou com: Sucesso a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
  EVENTO "Sucesso na execucao do backup FULL via DATAPUMP" 0
else
   mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.erro
  echo "--> Finalizou com: ERRO a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
  EVENTO "ERRO na execucao do backup FULL via DATAPUMP" 2 ${ARQ_LOG_GERAL}
 fi
DISPLAY "==============================="
DISPLAY "..............................: Fim"
}


INICIO_BACKUP="`date '+%d/%m/%Y %T'`"

if [ `echo $#` -lt "4" ]
then
   echo "Atencao: Falta de Parametros!!!
         sh TkBackupExpdp.sh <INSTANCE> <TIPO DE BACKUP> <RETENCAO DO BACKUP> <BACKUP MONITORADO>
         Opcoes: owner -> Faz backup por owner.
                 full  -> Faz backup full da base.
         Exemplo:sh TkBackupExpdp.sh $ORACLE_SID owner 3 S"
   exit 3
fi

# Recebe parametros

export INSTANCE=`echo $1`
export TIPO=`echo $2 | tr "a-z" "A-Z"`
export RETENCAO_LOG=30
export RETENCAO_DMP=`echo $3`
export BKP_MONITORADO=`echo $4 | tr "a-z" "A-Z"`

#
# Definicao de variaveis do shell
#
case ${INSTANCE} in
        treina )echo

        export ORACLE_BASE=/orabin01/app/oracle
        export ORACLE_HOME=/orabin01/app/oracle/product/12.1.0.2/dbhome_2
        export PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin
        export ORACLE_OWNER=oracle
        export ORACLE_VERSION=12.1
        export ORACLE_SID=${INSTANCE}
        export ORACLE_TERM=xterm
        export THREADS_FLAG=native
        export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
        export EDITOR=vi
        export TNS_ADMIN=$ORACLE_HOME/network/admin
                 ;;
      *) # Parametros Nao Definidos
         echo "Parametros nao Definidos para ORACLE_SID=${INSTANCE}"
         exit 4
esac


servername=`uname -n`

if  [ $servername = "srvivlmbd02" ]
then
        export DIR_BASE=/orabackup/Databases/datapump_treina/export
        export DIR_DMP=${DIR_BASE}/files
        export DIR_TMP=${DIR_BASE}/tmp
        export DIR_LOG=${DIR_BASE}/log
        export ARQ_LOG_PROCESSO=${DIR_TMP}/Export_processo.log
        export TMP_FILE2=${DIR_TMP}/export_full_${INSTANCE}.tmp
        export USER_TABLES=${DIR_TMP}/tk_bkp_exclui_tabela.txt
        export ERRO=${DIR_TMP}/Erro.log
        export SEP_ERRO=${DIR_TMP}/SEP_Erro.log
        export LOG_COMPARA=${DIR_TMP}/ComparaTabela.txt
        export ARQ_LOG_GERAL=${DIR_LOG}/${INSTANCE}.Expdp.Geral.`date +%Y%m%d%H`.log
        export ARQ_OWNER=${DIR_TMP}/Lista_owner_${INSTANCE}.tab
        export SCN_ATUAL=${DIR_TMP}/scn_${INSTANCE}.txt
        export PROC_SUCESS="successfully completed"
        #export EMAIL=joao.vitor@teiko.com.br
        export USER_EXPORT=teikobkp
        export USER_EXPORT_PASSWORD=bkpokiet
        export STATUS=OK
        export STATUS_GERAL=OK
        export FAROL_HOME=/usr/local/Teiko/Farol
        export FAROL=$FAROL_HOME/farolevent.sh
        export user_remoto=teiko
        export senha_remoto='$tudo100%'
        export BACKUP_REMOTO=0
        #Parametro IDIOMA portugues='$7' ingles='$5' Exemplo: export IDIOMA='$5'
        export IDIOMA='$5'

else

  echo " - Nome do servidor invalido : $servername"
        exit 5
fi


DISPLAY "Inicio do Backup .............: Expdp"
DISPLAY "Parametros Recebidos..........:"
DISPLAY "--> Instancia.................: ${INSTANCE}"
DISPLAY "--> Tipo do Backup............: ${TIPO}"
DISPLAY "--> Retencao dos DMPs.........: ${RETENCAO_DMP}"
DISPLAY "--> Retencao dos Logs.........: ${RETENCAO_LOG}"
DISPLAY "--> Backup Monitorado?........: ${BKP_MONITORADO}"
DISPLAY "==============================="



if [ "${TIPO}" = "OWNER" ]
then
   ERROR_COUNT=0
   DESABILITA_JOB
   EXPORT_OWNER
   if [ ${BACKUP_REMOTO} = 1 ]
   then
      REMOTO
   fi
HABILITA_JOB
# Define o Backup das linhas
elif [ "${TIPO}" = "FULL" ]
then
   # Define o Backup das linhas
   EXPORT_FULL
      if [ ${BACKUP_REMOTO} = 1 ]
                then
                REMOTO
      fi
else
   DISPLAY "Parametro Invalido..........: TIPO=${TIPO}"
   exit 6;
fi

# Manutencao arquivos

find ${DIR_TMP}/*  -mtime -1 -print -exec rm -f {} \; > /dev/null 2>&1

find ${DIR_LOG}/* -mtime +${RETENCAO_LOG} -print -exec rm -f {} \; > /dev/null 2>&1

find ${DIR_DMP}/*.dmp -mtime +${RETENCAO_DMP} -print -exec rm -f {} \; > /dev/null 2>&1

find ${DIR_DMP}/*.dmp.gz -mtime +${RETENCAO_DMP} -print -exec rm -f {} \; > /dev/null 2>&1
