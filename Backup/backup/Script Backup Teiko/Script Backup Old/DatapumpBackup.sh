[oracle@shosbd ~]$ cat /orabackup/dbprod/datapump/script/DatapumpBackup.sh
set -x
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
#######################################################
# Descricao:                                          #
#######################################################
# Descricao: Rotina via Expdp (datapump) por:         #
#    Opcoes: owner -> Faz backup por owner.           #
#            full  -> Faz backup full da base.        #
#   Exemplo:sh TkBackupExpdp.sh $ORACLE_SID owner 3 S #
#######################################################

# Definicao de funcoes

COPIA_REMOTA(){
export RETENCAO=10
export BASE_DIR=/orabackup/dbprod/datapump
export LOCAL_DIR=/bkpremoto
export REMOTE_DIR=//shoshbd/backup/dbprod/datapump
export EXTERNO_DIR=/hdexterno
export BACKUP_DIR=${BASE_DIR}/file
export STATUS1=0
export STATUS2=0

#if [ ${STATUS1} == 0 ]; then
#   sudo  /bin/umount -l ${LOCAL_DIR} > /dev/null
#   sudo  /bin/umount -l ${EXTERNO_DIR} > /dev/null

#   echo "Montando filesystem do backup remoto..." >> $ARQ_LOG_GERAL 2>&1
#   sudo  /sbin/mount.cifs ${REMOTE_DIR} ${LOCAL_DIR} -o username=oracle,password=oracle >> $ARQ_LOG_GERAL 2>&1
#   STATUS1=$?

#   echo "Montando filesystem do backup HD externo..." >> $ARQ_LOG_GERAL 2>&1
#   sudo  /bin/mount ${EXTERNO_DIR} >> $ARQ_LOG_GERAL 2>&1
#   STATUS2=$?

#   if [ ${STATUS1} == 0 ] && [ ${STATUS2} == 0 ]; then
      echo "Copiando arquivos do backup logico.." >> $ARQ_LOG_GERAL 2>&1
      sudo  find ${LOCAL_DIR}/file/* -mtime +${RETENCAO} -exec rm -f {} \; >> $ARQ_LOG_GERAL 2>&1

      sudo  rsync -v --ignore-existing ${BASE_DIR}/file/* ${LOCAL_DIR}/file
      STATUS1=$?

      echo "Copiando arquivos do backup logico HD.." >> $ARQ_LOG_GERAL 2>&1
      sudo  find ${EXTERNO_DIR}/dbprod/datapump/file/* -mtime +${RETENCAO} -exec rm -f {} \; >> $ARQ_LOG_GERAL 2>&1
      sudo  rsync -v --ignore-existing ${BASE_DIR}/file/* ${EXTERNO_DIR}/dbprod/datapump/file
      STATUS2=$?

#      if [ ${STATUS1} == 0 ] && [ ${STATUS2} == 0 ]; then
#         echo "Desmontando filesystem do backup remoto..." >> $ARQ_LOG_GERAL 2>&1
#         sudo  /bin/umount -l ${LOCAL_DIR} >> $ARQ_LOG_GERAL 2>&1
#         STATUS1=$?

#         echo "Desmontando filesystem do backup HD Externo..." >> $ARQ_LOG_GERAL 2>&1
#         sudo  /bin/umount -l ${EXTERNO_DIR} >> $ARQ_LOG_GERAL 2>&1
#         STATUS2=$?
#      fi
#   fi
#fi

}

DISPLAY(){
echo "[`date '+%d/%m/%Y %T'`] $*" >> $ARQ_LOG_GERAL
}


EVENTO(){
# Funcao que efetua o envio de evento para o monitoramento e/ou por e-mail

  NR_PARAMETRO=`echo $#`
  DESCRICAO_MENSAGEM="$1"
  SEVERIDADE_MENSAGEM=$2
  ANEXO_MENSAGEM=$3


  if [ ${BKP_MONITORADO} = "S" ]
  then
    if [ ${NR_PARAMETRO} = 3 ]
    then
      #${JAVA_PATH} -jar ${TKMON_SCRIPT} --alvo=${INSTANCE} --aplicacao=Backup_Teiko --objeto=exdp_tasy --severidade=${SEVERIDADE_MENSAGEM} --im=exdp_tasy --anexo=${ANEXO_MENSAGEM} --mensagem=${DESCRICAO_MENSAGEM}
      cat ${ANEXO_MENSAGEM} | mail -s "${DESCRICAO_MENSAGEM}" ${EMAIL_AVISO}
    fi
    if [ ${NR_PARAMETRO} = 2 ]
    then
      #${JAVA_PATH} -jar ${TKMON_SCRIPT} --alvo=${INSTANCE} --aplicacao=Backup_Teiko --objeto=exdp_tasy --severidade=${SEVERIDADE_MENSAGEM} --im=exdp_tasy --mensagem=${DESCRICAO_MENSAGEM}
      cat ${ANEXO_MENSAGEM} | mail -s "${DESCRICAO_MENSAGEM}" ${EMAIL_AVISO}
    fi

  fi

}


GERA_OWNER(){
# Funcao para Gerar Lista de todos os owner da base com tabelas
${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/$USER_EXPORT_PASSWORD@$INSTANCE 2>&1 <<EOF
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${ARQ_OWNER}
select distinct owner
from sys.dba_tables
where owner not in ('SYS', 'SYSTEM', 'PUBLIC', 'TSMSYS', 'OUTLN', 'SYSMAN', 'ORDSYS',
                    'MDSYS', 'CTXSYS', 'ORDPLUGINS', 'LBACSYS', 'XDB',
                    'SI_INFORMTN_SCHEMA', 'DIP', 'DBSNMP', 'EXFSYS', 'WMSYS',
                    'ORACLE_OCM', 'ANONYMOUS', 'XS\$NULL', 'APPQOSSYS')
order by 1;
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
${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/$USER_EXPORT_PASSWORD@$INSTANCE 2>&1 <<EOF
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


EXPORT_OWNER()
{
# Gera A lista de Usuarios com tabelas
GERA_OWNER
# executa Expdp
for USUARIO in `cat ${ARQ_OWNER}`
do

  #Captura SCN da base de dados
  CAPTURA_SCN
  export SCN=`cat ${SCN_ATUAL}`
  ARQ_LOG=${INSTANCE}.${USUARIO}.`date +%Y%m%d%H`
  ARQ_DMP=${INSTANCE}.${USUARIO}%U.`date +%Y%m%d%H`.dmp

  DISPLAY "Expdp do Usuá.............: ${USUARIO}"
  DISPLAY "Inicio........................: `date '+%d/%m/%Y %T'`"

  expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@$INSTANCE DIRECTORY=DATA_PUMP_HD FLASHBACK_SCN=$SCN VERSION=10.2 SCHEMAS='\"'${USUARIO}'\"' DUMPFILE=${ARQ_DMP} logfile=${ARQ_LOG} filesize=5000M 1>>/dev/null 2>>/dev/null


#Verifica se o backup foi executado com sucesso
if [ -e ${DIR_DMP}/${ARQ_LOG} ]
then
  if [ `cat ${DIR_DMP}/${ARQ_LOG} | grep -c "Export terminated unsuccessfully"` -ne 0 ] || [ `cat ${DIR_DMP}/${ARQ_LOG} | egrep -c "ORA-|EXP-"` -ne 0 ]
  then
    GERAR_LST_ORA "${DIR_DMP}/${ARQ_LOG}"
    if [ "${RSP_ORA}" -eq "1" ]; then
      FIM_EXPORT=ERRO
    else
      FIM_EXPORT=OK
    fi
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

#COPIA_REMOTA

#Verifica se todo o procedimento do backup de cada owner foi efetuado com sucesso
if [ "${FIM_EXPORT}" = "OK" ] && [ "${FIM_COMPACTACAO}" = "OK" ]
then
  export STATUS=OK
  DISPLAY "Fim...........................: `date '+%d/%m/%Y %T'`"
  mv ${DIR_DMP}/${ARQ_LOG} ${DIR_LOG}/${ARQ_LOG}.ok
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
    EVENTO "Sucesso na execucao do backup OWNER via DATAPUMP" 0 ${ARQ_LOG_GERAL}
else
    EVENTO "ERRO na execucao do backup OWNER via DATAPUMP" 2 ${ARQ_LOG_GERAL}
fi



}

GERAR_LST_ORA(){
SCN=`echo ${SCN} | sed 's/ *$//g'`
echo "awk -f ${DIR_SCRIPT}/tk.awk $1 > ${DIR_TMP}/ORA-01466_${SCN}.lst"
awk -f ${DIR_SCRIPT}/tk.awk $1 > ${DIR_TMP}/ORA-01466_${SCN}.lst
${ORACLE_HOME}/bin/sqlplus -s ${USER_EXPORT}/$USER_EXPORT_PASSWORD@$INSTANCE 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${DIR_TMP}/tk_bkp_exclui_tabela.txt
select '"'||owner||'"."'||tabela||'"' from tk_bkp_exclui_tabela group by owner,tabela;
spool off;
quit
EOF
achou=0
for i in `cat ${DIR_TMP}/ORA-01466_${SCN}.lst`
do
  AC=`cat ${DIR_TMP}/tk_bkp_exclui_tabela.txt | grep -c ${i}`
  if [ ${AC} -ne 1 ]; then
    echo ${i} >> ${DIR_TMP}/tabelas_ORA-01466_${SCN}.lst
    achou=1
  fi
done
export RSP_ORA=${achou}
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

  expdp userid=${USER_EXPORT}/${USER_EXPORT_PASSWORD}@$INSTANCE DIRECTORY=DATA_PUMP_HD FLASHBACK_SCN=$SCN VERSION=10.2 FULL=Y DUMPFILE=${ARQ_DMP} logfile=${ARQ_LOG} filesize=5000M 1>>/dev/null 2>>/dev/null

if [ -e ${DIR_DMP}/${ARQ_LOG} ]
then
  if [ "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "Export terminated unsuccessfully")" != "" || "$(cat ${DIR_DMP}/${ARQ_LOG} | grep -e "ORA-" -e "EXP-")" != "" ]
  then
    echo "--> Finalizou com: ERRO a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
    EVENTO "ERRO na execucao do backup FULL via DATAPUMP" 2 ${ARQ_LOG_GERAL}
  else
    echo "--> Finalizou com: Sucesso a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
    EVENTO "Sucesso na execucao do backup FULL via DATAPUMP" 0
  fi
else
  echo "--> Finalizou com: ERRO a Execucao do Backup FULL via DATAPUMP - Data: `date`" >> ${ARQ_LOG_PROCESSO}
  EVENTO "ERRO na execucao do backup FULL via DATAPUMP" 2 ${ARQ_LOG_GERAL}
fi

  DISPLAY "..............................: Fim"

# Atualiza Log Geral Com Resumo

DISPLAY "Fim do Backup Full via Expdp"

mv ${DIR_DMP}/*.log ${DIR_LOG}

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
export RETENCAO_DMP=$3
export BKP_MONITORADO=`echo $4 | tr "a-z" "A-Z"`

#
# Definicao de variaveis do shell
#
case ${INSTANCE} in
    dbprod)echo

        export ORACLE_BASE=/orabin/app/oracle
        export ORACLE_HOME=/orabin/app/oracle/product/11.2.0/db
        export PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin
        export ORACLE_OWNER=oracle
        export ORACLE_SID=dbprod
        export ORACLE_TERM=xterm
        export THREADS_FLAG=native
        export LD_LIBRARY_PATH=$ORACLE_BASE/lib:$LD_LIBRARY_PATH
        export EDITOR=vi
        export TNS_ADMIN=$ORACLE_HOME/network/admin
                 ;;
      *) # Parametros Nao Definidos
         echo "Parametros nao Definidos para ORACLE_SID=${INSTANCE}"
         exit 4
esac


servername=`uname -n`

if  [ $servername = "shosbd.unimed147.local" ]
then
        export DIR_SCRIPT=/orabackup/dbprod/datapump/script
        export DIR_DMP=/hdexterno/dbprod/datapump/file/
        export DIR_TMP=/hdexterno/dbprod/datapump/tmp
        export DIR_LOG=/hdexterno/dbprod/datapump/log
        export ARQ_LOG_PROCESSO=${DIR_TMP}/Export_processo.log
        export ARQ_LOG_GERAL=/var/log/backup/${INSTANCE}.Expdp.Geral.`date +%Y%m%d%H`.log
        export ARQ_OWNER=/usr/tmp/Lista_owner_${INSTANCE}.tab
        export SCN_ATUAL=/usr/tmp/scn_${INSTANCE}.txt
        export EMAIL_AVISO="sas@unimednp.com.br"
        export USER_EXPORT=teikobkp
        export USER_EXPORT_PASSWORD=bkpokiet
        export STATUS=OK
        export STATUS_GERAL=OK
        export JAVA_PATH=/usr/local/Teiko/Java/jre/bin/java
        export TKMON_SCRIPT=/usr/local/Teiko/TkMonitor_Client/tkmonitor_evento.jar
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

   EXPORT_OWNER
   # Define o Backup das linhas
elif [ "${TIPO}" = "FULL" ]
then
   # Define o Backup das linhas
   EXPORT_FULL
else
   DISPLAY "Parametro Invalido..........: TIPO=${TIPO}"
   exit 6;
fi

# Manutencao arquivos
find ${DIR_LOG}/* -mtime +${RETENCAO_LOG} -print -exec rm -f {} \; > /dev/null 2>&1
find ${DIR_DMP}/*.dmp.gz -mtime +${RETENCAO_DMP} -print -exec rm -f {} \; > /dev/null 2>&1
