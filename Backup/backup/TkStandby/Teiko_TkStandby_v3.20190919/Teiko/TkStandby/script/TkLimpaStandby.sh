# Programa   : TkLimpaStandby.sh
# Funcao     : 1) Limpeza dos Logs
#              2) Limpeza dos Archive em Procucao e Standby Se Opcao RemoveArchive=BACKUP
#
# Autor      : Djalma Luciano Zendron
# Data       : 25/08/2007
# Sintaxe    : sh TkLimpaStandby.sh <OracleSid>
# Alterado por :  Djalma Luciano Zendron - Teiko
# .............:  Compatibilidade com RAC
# Data         :  25/08/2007
###############################################################################

F_Inicio(){
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

####################
# Varivaies Locais #
####################
nm_programa=TkLimpaStandby
ArqLogProcesso="${DirLog}/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.log"
ArqLogTemp="/tmp/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.$$"
trap 'rm -f ${ArqLogTemp}' 0
tk_severidade=0
STATUS=OK
StepCount=0

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
   cmd_opcao=" -q " ; export cmd_opcao
fi

###########################################
# Dados gerais do Processo de Atualizacao #
###########################################
echo " ">> ${ArqLogProcesso}
F_Display "### Inicio... Inicio do Processo de Sincronizacao do Banco Standby com o Banco de Producao ###"
echo " -------------------Dados de Configuracao do Ambiente------------------------------------------------
######################################### Servidor Standby ###########################################
-> Versao do Produto + Data de Liberacao ..........: ${DtLibTkStandby}
-> Hostname servidor Standby ......................: $hostname_servidor_standby
-> ORACLE_SID  Standby ............................: $ORACLE_SID
-> ORACLE_HOME Standby ............................: $ORACLE_HOME
-> Diretorio Arc. Copiados ........................: ${DirArchiveDestCopy}
-> Diretorio Arc. Em Processo de Atualizacao ......: ${DirArchiveDestStandby}
-> Diretorio Arc. Jah Aplicados ...................: ${DirArchiveDestApplied}
-> Script Shell............. ......................: ${DirBase}/standby/script/${nm_programa}.sh           " >> ${ArqLogProcesso}
echo "################################ Servidor(es) Primario(os) ###########################################
-----------------------------------------------------------------------------------------------------" >> ${ArqLogProcesso}
}

F_Valida_Ambiente(){
#############################################
# Valida a Configuracao do Ambiente Standby #
#############################################

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
   tk_severidade=2
   F_Display   "Erro, Disparado o Processo de Atualizacao com o Processo de AtivaStandbyReadWrite em Andamento."
   F_Display   "Erro, Verifique se o Arquivo de LOCK eh antigo ${DirTmp}/${ORACLE_SID}_AtivaStandbyReadWrite.lock"
   F_Notifica  "Erro, Disparado o Processo de Atualizacao com o Processo de AtivaStandbyReadWrite em Andamento."
   exit 1
fi
if [ -f ${ArqCtlMTCluster} ]
then
   STATUS=ERRO
   tk_severidade=2 
   F_Display   "Erro, Disparado o Processo de Atualizacao com o Pacote do MTCLUSTER Ativo no servidor Standby"
   F_Display   "Erro, Verifique se o Arquivo de LOCK eh antigo ${ArqCtlMTCLUSTER} "
   F_Notifica  "Erro, Disparado o Processo de Atualizacao com o Pacote do MTCLUSTER Ativo no servidor Standby"
   exit 1
fi

if [ ! -d $DirArchiveDestApplied ]
then
     STATUS=ERRO
     tk_severidade=2
     F_Display   "Erro, Nao Encontrou o Diretorio de Backup no Standby:  (${DirArchiveDestApplied})"
     F_Notifica  "Erro, Nao Encontrou o Diretorio de Backup no Standby:  (${DirArchiveDestApplied})"
     exit 1
fi

if [ ! -d $DirLog ]
then
     STATUS=ERRO
     tk_severidade=2
     F_Display   "Erro, Nao Encontrou o Diretorio de Log no Standby:  (${DirLog})"
     F_Notifica  "Erro, Nao Encontrou o Diretorio de Log no Standby:  (${DirLog})"
     exit 1
fi
F_Display "Sucesso, Configuracao OK!!!"

}
F_Controla_Execucao()
{
      echo "[`date '+%d/%m/%Y %T'`] Data da Ultima Execucao de Limpeza com Sucesso do Standby" > ${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl
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
      # Neste Caso o nao Sera enviado Mensagem, pois o MTMON Monitora o intervalo de Limpeza
      # Monitorando a data de atualizacao do arquivo TkLimpaStandby.ctl
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
F_Limpa ()
{

if [ "${RemoveArchive}" = "BACKUP" ] 
then
    echo "-------------------------------Regras Para Limpeza dos Archives---------------------------------------------------------------------------
Nota (1): Soh eh Limpo do servidor Primario os archives jah aplicados no standby e salvos para Backup (.bkp).
Nota (2): Soh eh Limpo do Servidor Secundario os archives jah aplicados.
Nota (3): No Standby so eh removido archives quando o diretorio (${DirArchiveDestApplied}) estiver com a taxa de ocupacao superior a ($Arch_Used_Optimizer}%).
------------------------------------------------------------------------------------------------------------------------------------------ " >> ${ArqLogProcesso}
    ##############################################
    # Procedimento de Limpeza Para SITE PRIMARIO #
    ##############################################
    STATUS=OK
    tk_severidade=0
    i=1
    while test ${i} -le ${#hostname_servidor_primario[@]}
    do 
      NrArchCorrenteStandby=999999999999999
      w_flag_NrThread=99999999
      w_flag_remocao=0
      F_Display "----------------------------------------------------------------------------------"
      F_Display "- Selecionando os Archive do Servidor Primario [$i]-(${hostname_servidor_primario[$i]})"
      F_Display "- Diretorio Origem  (${DirArchiveDestPrimario[$i]})"
      F_Display "----------------------------------------------------------------------------------"
      for ArchBKP in `ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "ls -tr ${DirArchiveDestPrimario[$i]}/ |grep "^${ORACLE_SID}" |grep ${SufixoArchive}|grep ${SufixoBackup}|sort " 2>> ${ArqLogProcesso}`
      do
         NrThread=`echo ${ArchBKP} |cut -f2 -d_`
         if [ "${w_flag_NrThread}" != "${NrThread}" ]
         then
             ########################################################################
             # Identifica o Numero do Ultimo Archive Aplicado no Standby por Thread #
             ########################################################################
             NrArchCorrenteStandby=`ls -rt ${DirArchiveDestApplied}/ |grep "^${ORACLE_SID}_${NrThread}_"|grep ${SufixoArchive} |tail -n1 |cut -f3 -d_ |cut -f1 -d. 2>>${ArqLogProcesso}`
             w_flag_NrThread=${NrThread}
         fi
         NrArchBKP=`echo ${ArchBKP}|cut -f3 -d_ |cut -f1 -d. `
         if [ "${NrArchBKP}" -lt "${NrArchCorrenteStandby}" ]
         then
             w_fag_remocao=1
             F_Display "Removendo o Archive (${ArchBKP})" 
             ssh ${cmd_opcao} ${hostname_servidor_primario[$i]} "rm -f ${DirArchiveDestPrimario[$i]}/${ArchBKP}" 2>> ${ArqLogProcesso}
             if [ "$?" != "0" ]
             then
                 STATUS=ERRO
                 tk_severidade=2
             fi
         fi
      done 
      if [ "${w_flag_remocao}" -eq "0" ] 
      then
         F_Display "Nenhum Archive (.bkp) Selecionado para Remocao" 
      fi
    i=$(($i+1))
    done
    
    if [ "${STATUS}" != "OK" ]  
    then
        F_Notifica "Erro, Na Limpeza dos Archives no(s) Site(s) Primario(s)!"
    fi
    
    ################################################
    # Procedimento de Limpeza Para SITE Secundario #
    ################################################
    STATUS=OK
    tk_severidade=0
    w_flag_remocao=0
    if [ "${hostname_servidor_secundario}" != "" ]
    then
        F_Display "----------------------------------------------------------------------------------"
        F_Display "- Selecionando os Archive do Servidor Secundario-(${hostname_servidor_Secundario})"
        F_Display "- Diretorio Origem  (${DirArchiveDestSecundario})"
        F_Display "----------------------------------------------------------------------------------"
        for ArchSecundario in `ssh ${cmd_opcao} "${hostname_servidor_secundario}" "ls -tr ${DirArchiveDestSecundario}/ |grep ${SufixoArchive}" 2>> ${ArqLogProcesso}`
        do     
             ########################################################################
             # Identifica o Numero do Ultimo Archive Aplicado no Standby por Thread #
             ########################################################################
             NrThread=`echo ${ArchSecundario} |cut -f2 -d_`
             NrArchUltApliStandby=`ls -rt ${DirArchiveDestApplied}/ |grep "^${ORACLE_SID}_${NrThread}_"|grep ${SufixoArchive} |tail -n1 |cut -f3 -d_ |cut -f1 -d. 2>>${ArqLogProcesso}`
             NrArchSecundario=`echo ${ArchSecundario}|cut -f3 -d_ |cut -f1 -d. `
             if [ "${NrArchSecundario}" -lt "${NrArchArchApliStandby}" ]
             then
                 w_fag_remocao=1
                 F_Display "Removendo o Archive (${ArchSecundario})" 
                 ssh ${cmd_opcao} ${hostname_servidor_secundario} "rm -f ${DirArchiveDestSecundario}/${ArchSecundario}" 2>> ${ArqLogProcesso}
                 if [ "$?" != "0" ]
                 then
                     STATUS=ERRO
                     tk_severidade=2
                 fi 
            fi 
        done
        if [ "${w_flag_remocao}" -eq "0" ] 
        then
            F_Display "Nenhum Archive Selecionado para Remocao" 
        fi
    fi
    if [ "${STATUS}" != "OK" ]  
    then
        F_Notifica "Erro, Na Limpeza dos Archives no Site Secundario!"
    fi
else
   F_Display "Tipo de Remocao Configurado eh diferente de (BACKUP)"
   F_Display "Nenhum Archive Serah Removido"
fi

    #############################################
    # Procedimento de Limpeza Para SITE STANDBY #
    #############################################
    STATUS=OK
    tk_severidade=0
    w_flag_remocao=0
    F_Display "----------------------------------------------------------------------------------"
    F_Display "- Selecionando os Archive do Servidor Standby-(${hostname_servidor_standby})"
    F_Display "- Diretorio Origem  (${DirArchiveDestApplied})"
    F_Display "----------------------------------------------------------------------------------"
    for ArchStandbyApplied in `ls -tr ${DirArchiveDestApplied}/ |grep ${SufixoArchive} 2>> ${ArqLogProcesso}`
    do
       # Verifica o % de Ocupacao do disco onde encontra-se os archives
       P_Ocupacao=`(df -vl ${DirArchiveDestApplied} | sed 's/^ /xx/g' |grep "%" |awk '{ print $5 }' | sed '/Use/d' |sed '/Usa/d' | sed 's/%//g' ) 2>> ${ArqLogProcesso}`
       if  [ "${P_Ocupacao}" -lt "${Arch_Used_Optimizer}" ]
       then
           break
       fi
       F_Display "Removendo o Archive (${ArchStandbyApplied})"
       rm -f ${DirArchiveDestApplied}/${ArchStandbyApplied} 2>> ${ArqLogProcesso}
       if [ "$?" != "0" ]
       then
           STATUS=ERRO
           tk_severidade=2
       else
           w_fag_remocao=1
       fi
    done

    if [ "${w_flag_remocao}" -eq "0" ]
    then
        F_Display "Nenhum Archive Selecionado para Remocao"
    fi

    if [ "${STATUS}" != "OK" ]
    then
        F_Notifica "Erro, Na Limpeza dos Archives no Site Standby!"
    fi

####################
# LIMPEZA DOS LOGS #
####################
F_Display "Limpando ${DirLog}/*.log com data superior a ${NrDiasRetencaoLogs} Dia(s)"
w_flag_remocao=0
for ArqLog in `find $DirLog/ -mtime +${NrDiasRetencaoLogs} |grep .log 2>> $ArqLogProcesso` 
do
        w_flag_remocao=1
        rm -f ${DirLog}/${ArqLog} 2>> ${ArqLogProcesso}
        if [ "$?" != "0" ]
        then
           STATUS=ERRO
           tk_severidade=1
        fi
done

if [ "${w_flag_remocao}" -eq "0" ] 
then
    F_Display "Nenhum Arq. de Log Selecionado para Remocao!" 
fi

if [ "${STATUS}" != "OK" ]  
then
        F_Notifica "Erro, Na Limpeza dos Logs no Site Standby!"
fi

###########################
# LIMPEZA DOS ARQ. DE SLA #
###########################
F_Display "Limpando ${DirSLA}/*.txt com data superior a ${NrDiasRetencaoLogs} Dia(s)"
w_flag_remocaosla=0
for ArqSLA in `find $DirSLA/ -mtime +${NrDiasRetencaoLogs} |grep .txt 2>> $ArqLogProcesso`
do
        w_flag_remocaosla=1
        rm -f ${DirSLA}/${ArqSLA} 2>> ${ArqLogProcesso}
        if [ "$?" != "0" ]
        then
           STATUS=ERRO
           tk_severidade=1
        fi
done

if [ "${w_flag_remocaosla}" -eq "0" ] 
then
        F_Display "Nenhum Arq. de SLA Selecionado para Remocao!" 
fi
    
if [ "${STATUS}" != "OK" ]  
then
        F_Notifica "Erro, Na Limpeza dos Arq. de SLA  no Site Standby!"
fi
}

########################
# Controle de Processo #
########################
# Varivaies Locais
Nm_programa=TkLimpaStandby

# Inicializa variaveis de ambiente
F_Inicio $1

# Valida Configuracao do Ambiente
F_Valida_Ambiente

# Executa Limpeza de Archives e Logs
F_Limpa

# Atualiza Controle de Execucao
F_Controla_Execucao
