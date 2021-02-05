# Programa   : TkCopiaArchives.sh
# Funcao     : 1) Copia dos Archive de Ambiente de Producao para Standby
#
# Autor      : Djalma Luciano Zendron - Teiko
# Data       : 25/08/2007
# Sintaxe    : sh TkCopiaArchives.sh <OracleSid>
# Alterado por :  Djalma Luciano Zendron - Teiko
# .............:  Utilizar o ssh e scp com chave privada
# Data         :  27/06/2005
###############################################################################

F_Inicio(){
####################
# Varivaies Locais #
####################
nm_programa=TkCopiaArchive
ArqLogProcesso="${DirLog}/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.log"
ArqLogTemp="/tmp/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.$$"
ArqResumoAtu="${DirLog}/${ORACLE_SID}_TkAtualizaStandby.atu" 
ArqExTableSLA="${DirSLA}/RPO_${ORACLE_SID}_`date '+%Y%m%d'`.txt"
tk_severidade=0
STATUS=OK
StepCount=0
trap 'rm -f ${ArqLogTemp}' 0

#######################################
# Verifica se a Copia Esta executando #
#######################################
ps -ef |grep "${nm_programa}.sh ${1}" |grep -v $$ |grep -v "sh -c sh"|wc -l 1>/tmp/${nm_programa}.$$
nr_processos=`cat /tmp/${nm_programa}.$$`
rm -f /tmp/${nm_programa}.$$
if [ "${nr_processos}" -gt "0" ]
then
   F_Display "Atencao: O Processo de ${nm_programa} Executando!!!"
   F_Display "Tente Novamente mais Tarde!!!"
   exit 12
fi

######################################
# Dados gerais da copia dos archives #
######################################
echo " ">> ${ArqLogProcesso}
F_Display "### Inicio... Copiando Archives do Servidor Primario para o Standby ###"
echo " -------------------Dados de Configuracao do Ambiente------------------------------------------------
######################################### Servidor Standby ###########################################
-> Versao do Produto + Data de Liberacao ..........: ${DtLibTkStandby}
-> Hostname servidor Standby ......................: $hostname_servidor_standby                              
-> ORACLE_SID  Standby ............................: $ORACLE_SID
-> ORACLE_HOME Standby ............................: $ORACLE_HOME
-> Diretorio Arq. Copiados ........................: ${DirArchiveDestCopy} 
-> Diretorio Arq. Prontos para Aplicar ............: ${DirArchiveDestStandby} 
-> Diretorio Arq. Jah Aplicados ...................: ${DirArchiveDestApplied}  
-> Diretorio Arq. Pendentes de Copia ..............: ${DirArchiveDestPending}
-> Script Shell............. ......................: ${DirBase}/standby/script/${nm_programa}.sh       
-> Mecanismo de copia dos Archives.................: scp                                                     " >> ${ArqLogProcesso}
echo "################################ Servidor(es) Primario(os) ########################################### " >> ${ArqLogProcesso}
i=1
while test ${i} -le ${#hostname_servidor_primario[@]}
do
   echo "-> Hostname servidor primario [$i]..................: ${hostname_servidor_primario[$i]}" >> ${ArqLogProcesso}
   i=$(($i+1))
done

i=1
while test ${i} -le ${#DirArchiveDestPrimario[@]}
do
   echo "-> LOG_ARCHIVE_DEST (Primario)[$i]..................: ${DirArchiveDestPrimario[$i]}" >> ${ArqLogProcesso}
   i=$(($i+1))
done

echo "#################################### Servidor Secundario #############################################
-> Hostname servidor Secundario ...................: $hostname_servidor_secundario                               
-> LOG_ARCHIVE_DEST (Secundario)...................: ${DirArchiveDestSecundario}
-----------------------------------------------------------------------------------------------------" >> ${ArqLogProcesso}

}

F_Controla_Execucao ()
{
      echo "[`date '+%d/%m/%Y %T'`] Data da Ultima Execucao com Sucesso!" > ${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl
      if [ "$?" != "0" ]
      then
         F_Display "Problema na atualizacao do arquivo ctl (${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl)"
      fi
}

F_Notifica ()
{
   # Parametro $*: subject do email
   msg="Banco(${ORACLE_SID}) - $*"

while true
do
  
   if [ "${TkNotifica}" = "MTMON" -a "${STATUS}" = "ERRO_MTMON" ]
   then
      #
      # Neste Caso o nao Sera enviado Mensagem, pois o MTMON Monitora o intervalo de atualizacao do standby
      # Monitorando a data de atualizacao do arquivo CopiaArchive.ctl
      # 
      break
   fi

   #########################
   # Integracao com MTSEND #
   #########################
   if [ "${TkNotifica}" = "MTSEND" -a "${STATUS}" = "OK" ]
   then
      mtsend.pl --email $email_destino_log --subject "$cliente-$nm_programa-$msg" --attach $ArqLogProcesso 1>>/dev/null
   elif [ "${TkNotifica}" = "MTSEND" -a "${STATUS}" != "OK" ]
   then
      mtsend.pl --email $email_destino_erro --subject "$cliente-$nm_programa-$msg" --attach $ArqLogProcesso 1>>/dev/null
   fi

   #######################
   # Integracao com MUTT #
   #######################
   if [ "${TkNotifica}" = "MUTT" -a "${STATUS}" = "OK" ]
   then
      mutt -a $ArqLogProcesso -s "$cliente-$nm_programa-$msg" $email_destino_log </dev/null
   elif [ "${TkNotifica}" = "MUTT" -a "${STATUS}" != "OK" ]
   then
      mutt -a $ArqLogProcesso -s "$cliente-$nm_programa-$msg" $email_destino_erro < /dev/null
   fi

   ########################
   # Integracao com MAILX #
   ########################
   if [ "${TkNotifica}" = "MAILX" -a "${STATUS}" = "OK" ]
   then
      (echo "Favor Verificar Anexo\!\!\!"; uuencode  $ArqLogProcesso $ArqLogProcesso ) |mailx -s "$cliente-$nm_programa-$msg" $email_destino_log </dev/null >>/dev/null
   elif [ "${TkNotifica}" = "MAILX" -a "${STATUS}" != "OK" ]
   then
      (echo "Favor Verificar Anexo\!\!\!"; uuencode  $ArqLogProcesso $ArqLogProcesso ) |mailx -s "$cliente-$nm_programa-$msg" $email_destino_log </dev/null >>/dev/null
   fi


   ########################
   # Integracao com MTMON #
   ########################
   if [ "${TkNotifica}" = "MTMON" -a "${STATUS}" = "OK" ]
   then
      /usr/local/bin/mtmon_evento.pl --severidade=0 --aplicacao=TkStandby --objeto=${nm_programa} --eventual --notifica=${MTMON_NOTIFICA} --mensagem="${msg}" --repete
   elif [ "${TkNotifica}" = "MTMON" -a "${STATUS}" != "OK" ]
   then
      /usr/local/bin/mtmon_evento.pl --severidade=${tk_severidade} --aplicacao=TkStandby --objeto=${nm_programa} --mensagem="${msg}" --dump=${ArqLogProcesso} --eventual --notifica=${MTMON_NOTIFICA} --repete
   fi

   ########################
   # Integracao com FAROL #
   ########################
   #if [ "${TkNotifica}" = "FAROL" -a "${STATUS}" = "OK" ]
   #then
   #    sh ${FAROL_HOME}/farolevent.sh --alvo=${nm_alvo} --aplicacao=TkStandby --objeto=${nm_programa} --im=${nm_programa} --severidade=0 --mensagem=\"${msg}\" 1>> ${ArqLogProcesso} 2>> ${ArqLogProcesso}
   #elif [ "${TkNotifica}" = "FAROL" -a "${STATUS}" != "OK" ]
   #then
   #    sh ${FAROL_HOME}/farolevent.sh --alvo=${nm_alvo} --aplicacao=TkStandby --objeto=${nm_programa} --im=${nm_programa} --severidade=${tk_severidade} --mensagem=\"${msg}\" --anexo=${ArqLogProcesso} 1>> ${ArqLogProcesso} 2>> ${ArqLogProcesso}
   #fi

   # Sai do Laco
   break
done
   
}

F_Controla_SLA()
{
STATUS=OK
tk_severidade=0
# Atualiza o archivo External Table Utilizado para Controlar o SLA
F_Display "Atualizando Controle para SLA" 
for ArchSLA in `ls ${DirSLA}/ |grep "^${ORACLE_SID}" |grep ".date" 2>>${ArqLogProcesso}`
do
 DtReplicacao=`cat ${DirSLA}/${ArchSLA} 2>>${ArqLogProcesso}`
 NrThreadSLA=`echo ${ArchSLA} |cut -f2 -d_ 2>>${ArqLogProcesso}`
 NrSeqSLA=`echo ${ArchSLA} |cut -f3 -d_ |cut -f1 -d. 2>>${ArqLogProcesso}`
 echo "${NrThreadSLA}:${NrSeqSLA}:${DtReplicacao}" >> ${ArqExTableSLA} 2>> ${ArqLogProcesso}
 if [ "${?}" != "0" ]
 then
    STATUS=ERRO
    tk_severidade=1
    F_Display "Erro, Na Atualizacao da External Table de Controle do SLA."
 else
    rm -f ${DirSLA}/${ArchSLA}
 fi
done

if [ "${STATUS}" != "OK" ]
then
   F_Notifica "Erro, No Controle do SLA." 
else
   F_Display "Sucesso..."
fi
}

F_Display ()
{
StepCount="`expr $StepCount + 1`"

if [ "${DISPLAY_TELA}" = "S" ]
then
    echo "[ $StepCount ] `date '+%d/%m/%Y %T'` $*" | tee -a $ArqLogProcesso
else
    echo "[ $StepCount ] `date '+%d/%m/%Y %T'` $*" >> $ArqLogProcesso
fi
}

F_Valida_Ambiente ()
{
#############################################
# Valida a Configuracao do Ambiente Standby #
#############################################
STATUS=OK
tk_severidade=0

F_Display "Verificando Configuracao do Ambiente Standby" 

if [ "`hostname`" != "$hostname_servidor_standby" ]
then
    STATUS=ERRO
    tk_severidade=2
    F_Display      "Erro, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    F_Notifica     "Erro, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    exit 1
fi

if [ -f ${DirTmp}/${ORACLE_SID}_AtivaStandbyReadWrite.lock ]
then
   STATUS=ERRO
   tk_severidade=1
   F_Display      "Atencao: Disparado a Copia dos Archives com o Processo de AtivacaoReadWrite em Andamento."
   F_Display      ".......: Verifique se o Arquivo de LOCK eh antigo ${DirTmp}/${ORACLE_SID}_AtualizaStandbyReadWrite.lock"
   F_Notifica     "Erro, Disparado a Copia dos Archives com o Processo de AtivacaoReadWrite em Andamento."
   exit 13
fi

if [ -f "${ArqCtlMTCLUSTER}" ]
then
   STATUS=ERRO
   tk_severidade=1
   F_Display      "Atencao: Disparado a Copia dos Archives com o Pacote do MTCLUSTER Ativo no servidor Standby"
   F_Display      ".......: Verifique se o Arquivo de LOCK eh antigo ${ArqCtlMTCLUSTER} "
   F_Notifica     "Erro, Disparado a Copia dos Archives com o Pacote do MTCLUSTER Ativo no servidor Standby"
   exit 14
fi

F_Display "Verificando a disponibilidade do(s) Diretório(s) de Archive(s)"
i=1
while test ${i} -le ${#hostname_servidor_primario[@]}
do
   # Valida o Diretorio do servidor Primario
   ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "test -d ${DirArchiveDestPrimario[$i]}" 1>>${ArqLogProcesso} 2>> ${ArqLogProcesso}
   if [ "${?}" != "0" ]
   then
       tk_severidade=1
       F_Display  "Aviso, Diretorio LOG_ARCHIVE_DEST Primario [$i] (${DirArchiveDestPrimario[$i]}), nao disponivel!"
       if [ "${hostname_servidor_secundario}" != "" ]
       then
           ssh ${cmd_opcao} "${hostname_servidor_secundario}" "test -d ${DirArchiveDestSecundario}" 1>>${ArqLogProcesso} 2>> ${ArqLogProcesso}
           if [ "${?}" != "0" ]
           then
               tk_severidade=2
               F_Display  "Aviso, Nao Encontrou o Diretorio (${DirArchiveDestSecundario}) no Servidor Secundario!"
           fi
       else
          tk_severidade=2
       fi
   else
       F_Display "Sucesso na verificação do servidor Primario [$i]"
   fi

   ##################################################
   # Notifica a Indisponibilidade de Algum Servidor #
   ##################################################
   if [ "$STATUS" = "ERRO" ] && [ "${tk_severidade}" = "2" ]
   then
        F_Display     "Erro, Problema com o acesso ao Diretório de Archives!!!"
        F_Notifica    "Erro, Problema com o acesso ao Diretório de Archives!!!"
        exit 1
    fi
    if [ "$STATUS" = "ERRO" ] && [ "${tk_severidade}" = "1" ]
    then
        F_Display     "Aviso, Problema com o acesso ao diretório de Archives do Servidor Primario, Utilizando o Servidor Secundario!!!"
        F_Notifica    "Aviso, Problema com o acesso ao diretório de Archives do Servidor Primario, Utilizando o Servidor Secundario!!!"
    fi
i=$(($i+1))
done

if [ ! -d "${DirArchiveDestStandby}" ]
then
     STATUS=ERRO
     tk_severidade=2
     F_Display   "Erro, Nao Encontrou o Diretorio de Archive no Standby: (${DirArchiveDestStandby}) "
     F_Notifica  "Erro, Nao Encontrou o Diretorio de Archive no Standby: (${DirArchiveDestStandby}) "
     exit 1
fi


if [ ! -d "${DirArchiveDestApplied}" ]
then
     STATUS=ERRO
     tk_severidade=2
     F_Display   "Erro, Nao Encontrou o Diretorio de Backup no Standby:  (${DirArchiveDestApplied})"
     F_Notifica  "Erro, Nao Encontrou o Diretorio de Backup no Standby:  (${DirArchiveDestApplied})"
     exit 1
fi

if [ ! -d "${DirArchiveDestCopy}" ]
then
     STATUS=ERRO
     tk_severidade=2
     F_Display   "Erro, Nao Encontrou o Diretorio de Copia no Standby: (${DirArchiveDestCopy}) "
     F_Notifica  "Erro, Nao Encontrou o Diretorio de Copia no Standby: (${DirArchiveDestCopy}) "
     exit 1
fi

if [ ! -d "${DirArchiveDestPending}" ]
then
     STATUS=ERRO
     tk_severidade=2
     F_Display   "Erro, Nao Encontrou o Diretorio de Arq. Pendentes de Copia no Standby: (${DirArchiveDestPending}) "
     F_Notifica  "Erro, Nao Encontrou o Diretorio de Arq. Pendentes de Copia no Standby: (${DirArchiveDestPending}) "
     exit 1
fi

F_Display "Sucesso, Configuracao OK!!!"

}

F_ListLastArchived(){

F_Display "Verificando a(s) Ultima(s) Sequencia(s) de cada Thread."
$ORACLE_HOME/bin/sqlplus -s "${stringconnect}" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set serveroutput on
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off

select  'LastArchived:'||thread#||':'||max(sequence#)
from GV\$ARCHIVED_LOG
where creator = 'ARCH'
  and  RESETLOGS_TIME  >= (select max(resetlogs_time) from v\$database_incarnation)
group by thread#
/
quit
EOF

if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=2
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Display  "Erro, Verificando a(s) Ultima(s) sequencia(s) de ArchiveLog em cada Thread"
   F_Notifica "Erro, Verificando a(s) Ultima(s) sequencia(s) de ArchiveLog em cada Thread"
   exit 1
else
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Display "Sucesso..."
fi
}

F_Copia_Archive(){

################################################
# Copia os Archives de Producao para o Standby #
################################################
F_Display "Identificando a sequencia dos ultimos Archives no Servidor Standby e no Site Primario"

#####for thread_stdby in `ls  ${DirArchiveDestStandby}/ |grep ${SufixoArchive}|grep "^${ORACLE_SID}" |cut -f2 -d_ |sort -u 2>> ${ArqLogProcesso}`
for thread_stdby in 1 2 3 4 5 
do
  ##########################################################################
  # Identificando os Últimos Archives copiados com sucesso para o Standby. #
  ##########################################################################
 #w_UltSeqThreadStdby=`ls -rt ${DirArchiveDestStandby}/ ${DirArchiveDestCopy}/ ${DirArchiveDestApplied}/ 2>>${ArqLogProcesso} |egrep ".ok|${SufixoArchive}"  |grep "${ORACLE_SID}_${thread_stdby}_" |tail -n1 |cut -f3 -d_ |cut -f1 -d. 2>>${ArqLogProcesso}`
  w_UltSeqThreadStdby=`ls -rt ${DirArchiveDestStandby}/ ${DirArchiveDestCopy}/ ${DirArchiveDestApplied}/ 3>>${ArqLogProcesso} |egrep ".ok|${SufixoArchive}"  |grep "${ORACLE_SID}_${thread_stdby}_" |sort |tail -n1 |cut -f3 -d_ |cut -f1 -d. 2>>${ArqLogProcesso}`
  if [ -z "$w_UltSeqThreadStdby" ]
  then
     w_UltSeqThreadStdby=0
  fi
  UltSeqThreadStdby[${thread_stdby}]="${w_UltSeqThreadStdby}"

  ###############################################################
  # Identificando os Ultimos archives gerados no site primario. #
  ###############################################################

  w_UltSeqThreadPrimary=`cat ${ArqLogTemp} |grep "^LastArchived:${thread_stdby}:" |cut -f3 -d: 2>>${ArqLogProcesso}`
  if [ -z "$w_UltSeqThreadPrimary" ]
  then
     w_UltSeqThreadPrimary=9999999999999
  fi
  UltSeqThreadPrimary[${thread_stdby}]="${w_UltSeqThreadPrimary}"

  ##########################################################
  # Identificando os Ultimos Archives Aplicado no Standby. #
  ##########################################################
  if [ -f ${ArqResumoAtu} ]
  then
     w_UltSeqThreadAplicado=`cat ${ArqResumoAtu} |grep "^LastAchUPDATE:${thread_stdby}:" |cut -f3 -d: 2>>${ArqLogProcesso}`
  fi

  if [ -z "${w_UltSeqThreadAplicado}" ]
  then
        w_UltSeqThreadAplicado=0
  fi
  UltSeqThreadAplicado[${thread_stdby}]="${w_UltSeqThreadAplicado}"

  F_Display  "Nr. Da Ultima Sequencia de ArchiveLog Copiada para o Site Standby ...: Thread ${thread_stdby} -> ${UltSeqThreadStdby[$thread_stdby]}"
  F_Display  "Nr. Da Ultima Sequencia de ArchiveLog Aplicada  no Banco Standby ....: Thread ${thread_stdby} -> ${UltSeqThreadAplicado[$thread_stdby]}"
  F_Display  "Nr. Da Ultima Sequencia de ArchiveLog Gerado    no  Site Primario ...: Thread ${thread_stdby} -> ${UltSeqThreadPrimary[$thread_stdby]}"

done

##############################################
# Identifica Archives Disponiveis para copia #
##############################################
STATUS=OK
tk_severidade=0
count=0
nr_proc_scp=9X9X9X9X
NrProcessoParalelo=`echo ${NrProcessoParalelo}`
i=1
while test ${i} -le ${#hostname_servidor_primario[@]}
do
  F_Display "----------------------------------------------------------------------------------"
  F_Display "- Buscando Archive do Servidor Primario [$i]-(${hostname_servidor_primario[$i]})" 
  F_Display "- Diretorio Origem  (${DirArchiveDestPrimario[$i]})"
  F_Display "- Diretorio Destino (${DirArchiveDestCopy})"
  F_Display "----------------------------------------------------------------------------------"
  for arq in `ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "ls -tr ${DirArchiveDestPrimario[$i]}/ |grep ${SufixoArchive}" 2>> ${ArqLogProcesso}`
  do
     #F_Display "--> Archive Selecionado Para Transmissao (${arq})"
     #########################################
     # Verifica o numero de processos ativos # 
     #########################################
     while true
     do
         w_flag=`ps -ef |egrep "scp.*${cmd_opcao}.*${hostname_servidor_primario[$i]}" |egrep "${nr_proc_scp}" |grep -v grep |wc -l`
         w_flag=`echo ${w_flag}` 
         if [ "${w_flag}" -ne "${NrProcessoParalelo}" ]
         then
             # O Maximo de Processos em Paralelo nao foi Atingido
             break
         else
             # O Limite Maximo de Processos em Paralelo foi Atingido
             F_Display "Limite Maximo de (${NrProcessoParalelo}) Processos Encontrado, Aguardando 5 segundos para continuar..."
             sleep 5
         fi 
     done

     while true
     do 
          
          #######################################################
          # Verifica se existe o archive do primario no standby #
          #######################################################
          arq_sem_sufixo=`echo ${arq} |cut -f1 -d"."`
          arq_seq_copy=`echo ${arq_sem_sufixo} |cut -f3 -d"_"`
          arq_thread_copy=`echo ${arq} |cut -f2 -d"_"` 
  
          #w_flag_existe_arc=0
          #w_flag_existe_arc=`ls ${DirArchiveDestApplied}/${arq_sem_sufixo}* ${DirArchiveDestStandby}/${arq_sem_sufixo}* ${DirArchiveDestCopy}/${arq_sem_sufixo}* 2>>/dev/null |wc -l`

          # Flag (se > que 0 ) indica a existencia de arquivos pendentes de tranferencia em funcao de erro.
          # Este archive deve ser transferido novamente.
          w_flag_pending=`ls ${DirArchiveDestPending}/${arq_sem_sufixo}* 2>>/dev/null |wc -l`
           
          #if [ "${w_flag_existe_arc}" -gt "0" ]  || \

          if [ "${arq_seq_copy}" -le "${UltSeqThreadAplicado[$arq_thread_copy]}" ] || \
             [ "${arq_seq_copy}" -le "${UltSeqThreadStdby[$arq_thread_copy]}"  ] && \
             [ "${w_flag_pending}" -le "0" ]
          then
             # o Archive jah esta no Servidor Standby
             # F_Display "Archive Jah Esta No Servidor Standby ou Jah Foi Aplicado"
             # F_Display "Nome do Arquive que jah esta no standby (${arq_sem_sufixo})"
             break
          else
             if [ "${arq_seq_copy}" -gt "${UltSeqThreadPrimary[$arq_thread_copy]}" ]
             then
                F_Display "Archive ($arq), esta sendo gerado e soh serah copiado na proxima copia!"
                break
             fi
             F_Display "--> Archive Selecionado Para Transmissao (${arq})"
             # Verifica a necessidade de Compactar o Archive antes de iniciar a Transmissao
             if [ "${CompactaArchive}" = "S" ]
             then
                w_flag_compacta=`echo ${arq} |grep "${SufixoCompactador}" |wc -l` 
                if [ "${w_flag_compacta}" -lt "1" ]
                then
                    # O Archive nao esta Compactado no site Primario
                    F_Display "Compactando o Archive Antes da Transmissao"
                    ssh ${cmd_opcao} ${hostname_servidor_primario[$i]} "${CMD_Compacta} ${DirArchiveDestPrimario[$i]}/${arq_sem_sufixo}*" 2>> ${ArqLogProcesso}
                    if [ "$?" != "0" ]
                    then
                       F_Display "Erro na Compactacao do Archive Antes da Transmissao"
                    fi
                fi
             fi
             # O Archive Nao Existe no servidor Standby
             > ${DirArchiveDestCopy}/${arq_sem_sufixo}.wrk
             F_Display "Copiando o Archive"
             scp ${cmd_opcao} ${hostname_servidor_primario[$i]}:${DirArchiveDestPrimario[$i]}/${arq_sem_sufixo}* $DirArchiveDestCopy/ 1>${DirArchiveDestCopy}/${arq_sem_sufixo}.wrk 2>${DirArchiveDestCopy}/${arq_sem_sufixo}.err &
             w_flag=$!
             # Recupera Horario de Copia da producao
             ssh ${cmd_opcao} ${hostname_servidor_primario[$i]} "date '+%Y%m%d%H%M%S'" 1> ${DirSLA}/${arq}.date 2>> ${ArqLogProcesso}
             if [ "$?" != "0" ]
             then
                F_Display "Problema Para Identificar data no Site Primario, assume data do standby!"
                echo "`date '+%Y%m%d%H%M%S'`"  1> ${DirSLA}/${arq}.date 2>> ${ArqLogProcesso}
             fi
             if [ "${nr_proc_scp}" = "9X9X9X9X" ]
             then
                  nr_proc_scp=${w_flag}
             else
                  nr_proc_scp="${nr_proc_scp}|${w_flag}"
             fi
          fi
          # Sai do Loop
          break
     done
  done

  if [ "${nr_proc_scp}" = "" ]
  then
     F_Display "Nenhum Archive Selecionado para Replicacao"
     exit 0
     # A nao existencia de um archive para replicar eh considerado possivel.
     # O controle do periodo de atualizacao do standby eh quem deve apontar uma falha se 
     # o periodo limite de atualizacao nao for atendido. 
  fi

  ###############################################
  # Inicio da Conferencia dos Archives Copiados #
  ###############################################
  F_Display "Verificando se todos os Processos (scp) em Paralelo Jah Terminaram"
  while true
  do
     w_flag=`ps -ef |egrep "scp.*${cmd_opcao}.*${hostname_servidor_primario[$i]}" |egrep "${nr_proc_scp}" |grep -v grep |wc -l`
     w_flag=`echo ${w_flag}`
     if [ "${w_flag}" -eq "0" ]
     then
        # Todos os Processos Terminaram
        break
     fi
     F_Display "Existe(m) (${w_flag}) scp em Paralelo Executando Ainda."
     sleep 5
  done
  for arq_sem_sufixo in `ls  ${DirArchiveDestCopy}/ |grep ".wrk" |cut -f1 -d. 2>> ${ArqLogProcesso}`
  do
     if [ -s ${DirArchiveDestCopy}/${arq_sem_sufixo}.err ]
     then
         STATUS=ERRO
         tk_severidade=1
         F_Display "Erro na Copia do Arquive (${arq_sem_sufixo}), do Servidor Primario (${hostname_servidor_primario[$i]})"
         echo "--------------------------------------------------------------------------------------" >> ${ArqLogProcesso}
         cat ${DirArchiveDestCopy}/${arq_sem_sufixo}.err >> ${ArqLogProcesso}
         echo "--------------------------------------------------------------------------------------" >> ${ArqLogProcesso}
         rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}*  
         rm -f ${DirSLA}/${arq_sem_sufixo}.${SufixoArchive}*
         ##############################################
         # Busca No Servidor Secundario se Disponivel #
         ##############################################
         if [ "${hostname_servidor_secundario}" != "" ]
         then
            F_Display "Buscando Archive do Servidor Secundario (${hostname_servidor_secundario})"
            for arq_secundario in `ssh ${cmd_opcao} "${hostname_servidor_secundario}" "ls -tr ${DirArchiveDestSecundario}/ |grep ${arq_sem_sufixo} " 2>> ${ArqLogProcesso}`
            do
               arq_sem_sufixo=`echo ${arq_secundario} |cut -f1 -d"."`
               #
               # Verifica a necessidade de Compactar o Archive antes de iniciar a Transmissao
               #
               if [ "${CompactaArchive}" = "S" ]
               then
                   w_flag_compacta=`echo ${arq_secundario} |grep "${SufixoCompactador}" |wc -l` 
                   if [ "${w_flag_compacta}" -lt "1" ]
                   then
                       # O Archive nao esta Compactado no site Primario
                       F_Display "Compactando o Archive (${DirArchiveDestSecundario}/${arq_sem_sufixo}), Antes da Transmissao"
                       ssh ${cmd_opcao} ${hostname_servidor_secundario} "${CMD_Compacta} ${DirArchiveDestSecundario}/${arq_sem_sufixo}*" 2>> ${ArqLogProcesso}
                       if [ "$?" != "0" ]
                       then
                          F_Display "Erro na Compactacao do Archive Antes da Transmissao"
                       fi
                   fi
               fi
               F_Display "Copiando ${DirArchiveDestSecundario}/${arq_sem_sufixo} ---> $DirArchiveDestCopy"
               scp ${cmd_opcao} ${hostname_servidor_secundario}:${DirArchiveDestSecundario}/${arq_sem_sufixo}* $DirArchiveDestCopy/ 1>${DirArchiveDestCopy}/${arq_sem_sufixo}.wrk 2>${DirArchiveDestCopy}/${arq_sem_sufixo}.err
               if [ "${?}" != "0" ]
               then
                   #
                   # Erro No Servidor Primario e Secundario o Aviso serah enviado com Severidade MAXIMA
                   #
                   STATUS=ERRO
                   tk_severidade=1
                   F_Display "Erro na Copia do Arquive (${arq_sem_sufixo}), do Servidor (${hostname_servidor_secundario})"
                   echo "--------------------------------------------------------------------------------------" >> ${ArqLogProcesso}
                   cat ${DirArchiveDestSecundario}/${arq_sem_sufixo}.err >> ${ArqLogProcesso}
                   echo "--------------------------------------------------------------------------------------" >> ${ArqLogProcesso}
                   rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}* 
                   F_Display  "Erro Na Copia de Archive do Servidor Primario e Secundario"

                   # Nao existe servidor secundario
                   F_CRIA_ARQ_PENDING

               else
                   #
                   # Sucesso no Servidor Secundario 
                   #
                   # Disponibiliza o archive copiado para ser utilizado na atualizacao
                   cd ${DirArchiveDestCopy}/
                   arq_copy=`ls ${arq_sem_sufixo}* |egrep -v ".wrk|.ok|.err" |grep ${SufixoArchive}` 
                   if [ -z "${arq_copy}" ]
                   then
                       STATUS=ERRO
                       tk_severidade=1
                       w_flag_severidade=1
                       F_Display "Erro na Copia do Archive (${arq_sem_sufixo})"
                       rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}*
                       F_CRIA_ARQ_PENDING
                   else 
                       mv ${DirArchiveDestCopy}/${arq_copy} ${DirArchiveDestCopy}/${arq_copy}.ok 2>>${ArqLogProcesso}
                       if [ "$?" != "0" ] 
                       then
                          STATUS=ERRO
                          tk_severidade=1
                          w_flag_severidade=1
                          F_Display "Erro No Rename do Archive Copiado com Sucesso para o Sufixo (.ok)"
                          rm -f ${DirArchiveDestCopy}/${arq_copy}* 
                          F_CRIA_ARQ_PENDING
                       else
                           # Atualiza da copia com sucesso para SLA
                           ssh ${cmd_opcao} ${hostname_servidor_secundario} "date '+%Y%m%d%H%M%S'" 1> ${DirSLA}/${arq_copy}.date 2>> ${ArqLogProcesso}
                           if [ "$?" != "0" ]
                           then
                              F_Display "Problema Para Identificar data no Site Secundario, assume data do standby!"
                              echo "`date '+%Y%m%d%H%M%S'`"  1> ${DirSLA}/${arq_copy}.date 2>> ${ArqLogProcesso}
                              STATUS=ERRO
                           fi
                           if [ "${w_flag_severidade}" = "0" ]
                           then
                              # Se entrar neste if entao a severidade nao completou o loop com 2(erro), entao a severidade pode ser diminuida
                              # A Severidade nao pode ser alterada para 1(Aviso) se ao final de um loop completo ela jah
                              # esteve em 2 (erro) para algum servidor
                               tk_severidade=1
                           fi
                           F_Display "Sucesso na Copia do Arquive (${arq_sem_sufixo}), do Servidor (${hostname_servidor_secundario})"
                           rm -f ${DirArchiveDestPending}/${arq_sem_sufixo}.pending 
                           count=`expr ${count} + 1`
                           if [ "${RemoveArchive}" = "REPLICADO" ] 
                           then
                               F_Display "Removendo Archive no Servidor Secundario!"
                               ssh ${cmd_opcao} "${hostname_servidor_secundario}" "rm -f ${DirArchiveDestSecundario}/${arq_sem_sufixo}${SufixoArchive}*" 1>>${ArqLogProcesso} 2>> ${ArqLogProcesso}
                               if [ "${?}" != "0" ]
                               then
                                  STATUS=ERRO
                                  tk_severidade=1
                                  F_Display "Erro Na Remocao!" 
                               fi
                           fi
                       fi
                       rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}.err ${DirArchiveDestCopy}/${arq_sem_sufixo}.wrk 
                   fi
               fi
            done 
         else
            # Nao existe servidor secundario
            F_CRIA_ARQ_PENDING
         fi
      else
         # Sucesso na Copia do Servidor Primario
         cd ${DirArchiveDestCopy}
         arq_copy=`ls ${arq_sem_sufixo}* |egrep -v ".wrk|.ok|.err" |grep ${SufixoArchive}` 
         if [ -z "${arq_copy}" ]
         then
            STATUS=ERRO
            tk_severidade=1
            w_flag_severidade=1
            F_Display "Erro na Copia do Archive (${arq_sem_sufixo})"
            rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}*
            F_CRIA_ARQ_PENDING
         else 
             mv ${DirArchiveDestCopy}/${arq_copy} ${DirArchiveDestCopy}/${arq_copy}.ok 2>>${ArqLogProcesso}
             if [ "$?" != "0" ] 
             then 
                STATUS=ERRO
                tk_severidade=1
                w_flag_severidade=1
                F_Display "Erro No Rename do Archive Copiado com Sucesso para o Sufixo (.ok)"
                rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}*
                F_CRIA_ARQ_PENDING
             else
                 rm -f ${DirArchiveDestPending}/${arq_sem_sufixo}.pending 
                 count=`expr ${count} + 1`
                 F_Display "Sucesso na Copia do Archive (${arq_copy})"
                 if [ "${RemoveArchive}" = "REPLICADO" ]
                 then
                    F_Display "Removendo Archive no Servidor Primario!"
                    ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "rm -f ${DirArchiveDestPrimario[$i]}/${arq_sem_sufixo}${SufixoArchive}* " 1>>${ArqLogProcesso} 2>> ${ArqLogProcesso}
                    if [ "${?}" != "0" ]
                    then
                        STATUS=ERRO
                        tk_severidade=1
                        F_Display "Erro Na Remocao!" 
                     fi
                 fi
             fi
         fi
         rm -f ${DirArchiveDestCopy}/${arq_sem_sufixo}.err ${DirArchiveDestCopy}/${arq_sem_sufixo}.wrk 
      fi
      if [ "${tk_severidade}" = "2" ]
      then
         # Completou o loop com a severidade em 2(erro), ativando flag para nao permitir que esta severidade seja menor quando sair do
         # loop
         w_flag_severidade=1 
      fi
  done 
i=$(($i+1))
done

#############################################
# Notifica A Ocorrencia de Erros Se Existir #
#############################################
if [ "$STATUS" = "OK" ]
then
    F_Display "Sucesso na Copia dos Archives. Copiados $count archives novos."
    ########################################################################
    # Atualiza Arquivo de controle para copia com sucesso.                 #
    # Utilizado pelo MTMON para avisar quando a copia nao esta executando. #
    ########################################################################
else
    F_Display     "Erro, Problema com a Copia de Archives, verifique o log!!!"
    #F_Notifica    "Erro, Problema com a Copia de Archives, verifique o log!!!" 
fi
}

F_CRIA_ARQ_PENDING()
{
 # Atualizar lista de archives pendentes de copia para serem copiados na proxima execucao
 F_Display "Executando a Funcao F_CRIA_ARQ_PENDING"
 echo "Erro na Copia. Este Archive Serah Copiado Na proxima Execucao do TKCopiaArchive.sh" > ${DirArchiveDestPending}/${arq_sem_sufixo}.pending
 if [ "$?" != "0" ]
 then
    F_Display "Erro na Criacao do Arquivo (${DirArchiveDestPending}/${arq_sem_sufixo}.pending)"
 fi
}

########################
# Controle de Processo #
########################
# Varivaies Locais
nm_programa=TkCopiaArchive

###############################
# Consiste parametro Recebido #
###############################
if [ "$#" -lt "1" ]
then
    echo "${nm_programa}.sh: Sintax Error!!!"
    echo "Use.............: TkCopiaArchive.sh <ORACLE_SID>"
    exit 1
fi
P_ORACLE_SID=`echo $1 |tr "a-z" "A-Z"`

#####################
# Atribui Variaveis #
#####################
. /usr/local/bin/Tkcfg.sh TEIKO TKSTANDBY
if [ "$?" != "0" ]
then
    echo "Erro Para Definir Variveis de Instalacao do TKSTANDBY" 
    exit 1
fi

#####################
# Variaveis Globais #
#####################
. /usr/local/bin/Tkcfg.sh TKSTANDBY ${P_ORACLE_SID}
if [ "$?" != "0" ]
then
    echo "Erro Para Definir Variaveis de Ambiente do TKSTANDBY"
    exit 1
fi

####################################################################
# Limitacao do Contrab a variavel eh atribuida novamente e funcoes # 
####################################################################
ORACLE_HOME=${ORACLE_HOME}         ; export ORACLE_HOME
ORACLE_BASE=${ORACLE_BASE}         ; export ORACLE_BASE
LD_LIBRARY_PATH=${LD_LIBRARY_PATH} ; export LD_LIBRARY_PATH
PATH=${PATH}                       ; export PATH
NLS_LANG=${NLS_LANG}               ; export NLS_LANG
ORACLE_SID=${ORACLE_SID}           ; export ORACLE_SID

StringAlvo=`echo ${StringAlvo} |tr "a-z" "A-Z" `
if [ "${StringAlvo}" = "N" ]
then
    nm_alvo=${ORACLE_SID}; export nm_alvo
else
    nm_alvo=${ORACLE_SID}_stdb ; export nm_alvo
fi

#
# Ativa Modo Silence/quiet do ssh e scp
#
UsarOpcaoSilence=`echo ${UsarOpcaoSilence} |tr "a-z" "A-Z" `

if [ "${UsarOpcaoSilence}" = "S" ]
then
   cmd_opcao="-q" ; export cmd_opcao
fi

#######################
# Chamada das Funcoes #
#######################
# (1) Inicializa variaveis de ambiente

F_Inicio $1

# (2) Valida Configuracao do Ambiente

F_Valida_Ambiente

F_ListLastArchived
# (3) Copia os Archives de Producao para Standby
F_Copia_Archive

# (4) Controle do SLA
F_Controla_SLA

# (5) Atualiza Contole de Execucao
F_Controla_Execucao
