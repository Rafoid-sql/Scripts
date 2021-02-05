# Programa   : TkAtivaStandbyReadOnly.sh
# Funcao     : 1) Montar banco Standby
#              2) Abrir banco em read only
#
# Autor      : Paulo Cesar Schorr - Teiko
#            : Djalma Luciano Zendron - Teiko
# Data       : 04/03/2004
#            
# Sintaxe    : sh TKAtivaStandbyReadOnly.sh <OracleSid>
#
###############################################################################
F_Inicio(){

clear
# Varivaies Locais
ArqLogProcesso="${DirLog}/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.log"
ArqLogTemp="/tmp/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.$$"
trap 'rm ${ArqLogTemp}' 0
STATUS=OK
StepCount=0

######################################
# Dados gerais da copia dos archives #
######################################
echo " ">> ${ArqLogProcesso}
F_Display "### Inicio... Copiando Archives do Servidor Primario para o Standby ###"
echo " -------------------Dados de Configuracao do Ambiente------------------------------------------------
######################################### Servidor Standby ###########################################
-> Hostname servidor Standby ......................: $hostname_servidor_standby                              
-> ORACLE_SID  Standby ............................: $ORACLE_SID
-> ORACLE_HOME Standby ............................: $ORACLE_HOME
-> Diretorio Arc. Copiados ........................: ${DirArchiveDestCopy} 
-> Diretorio Arc. Prontos para Aplicar ............: ${DirArchiveDestStandby} 
-> Diretorio Arc. Jah Aplicados ...................: ${DirArchiveDestApplied}  
-> Script Shell............. ......................: ${DirBase}/standby/script/${nm_programa}.sh       
-> Mecanismo de copia dos Archives.................: scp                                                     
-----------------------------------------------------------------------------------------------------" >> ${ArqLogProcesso}
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
      /usr/local/bin/mtmon_evento.pl --severidade=${Mtk_severidade} --aplicacao=TkStandby --objeto=${nm_programa} --mensagem="${msg}" --dump=${ArqLogProcesso} --eventual --notifica=${MTMON_NOTIFICA} --repete
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

F_Controla_Execucao()
{
      echo "[`date '+%d/%m/%Y %T'`] Data da Ultima Execucao com Sucesso!" > ${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl
      if [ "$?" != "0" ]
      then
         F_Display "Problema na atualizacao do arquivo ctl (${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl)"
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
Mtk_severidade=0

F_Display "Verificando Configuracao do Ambiente Standby" 

if [ "`hostname`" != "$hostname_servidor_standby" ]
then
    STATUS=ERRO
    Mtk_severidade=1
    F_Display      "Erro, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    F_Notifica     "Aviso, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    echo           "Erro, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    echo           "Digite <Enter> Para Retornar ao Menu!"
    read
    exit 1
fi


if [ -f "${ArqCtlMTCLUSTER}" ]
then
   STATUS=ERRO
   Mtk_severidade=1
   F_Display      "Atencao: Nao eh Permitido a Execucao do Shutdown com o Pacote do MTCLUSTER Ativo no servidor Standby"
   F_Display      ".......: Verifique se o Arquivo de LOCK eh antigo ${ArqCtlMTCLUSTER} "
   F_Notifica     "Aviso, Nao eh Permitido a Execucao do Shutdown com o Pacote do MTCLUSTER Ativo no servidor Standby"
   echo           "Atencao: Encontrato o Arquivo (${ArqCtlMTCLUSTER}), o que indica que o Pacote MTCLUSTER esta Ativo no Servidor Standby."
   echo           "         Voce nao pode Executar o Shutdown do Banco com este processo sendo Executado!" 
   echo           "Digite <Enter> Para Retornar ao Menu!"
   read a
   exit 14
fi

F_Display "Sucesso, Configuracao OK!!!"

}

F_Shutdown()
{

F_Display "Executando o Shutdown do Banco Standby"
echo      "Executando o Shutdown do Banco Standby"

$ORACLE_HOME/bin/sqlplus -s "/ as  sysdba" 1>>${ArqLogTemp} 2>>${ArqLogTemp}<<EOF
--whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 300
set linesize 132
set feedback off
shutdown immediate
quit
EOF
if grep "^ORA-" ${ArqLogTemp} |egrep -v "ORA-01109|ORA-01507" 1>>/dev/null 2>>/dev/null
then
   STATUS=ERRO
   Mtk_severidade=2
   cat ${ArqLogTemp} >> ${ArqLogProcesso}
   F_Display  "Erro, Na Execucao do Shutdown do Banco Standby"
   F_Notifica "Erro, Na Execucao do Shutdown do Banco Standby"
   cat ${ArqLogTemp}
   echo " 
Fim do processo, com Erro!!! 

Tecle <Enter>  para finalizar"
read a
exit 1
else
   cat ${ArqLogTemp} >> ${ArqLogProcesso}
   cat ${ArqLogTemp}
   F_Display  "Sucesso..."
   echo " 
Fim do processo, com Sucesso!!! 

Tecle <Enter>  para finalizar"
read a
fi
}
########################
# Controle de Processo #
########################
# Varivaies Locais
nm_programa=TkShutdownStandby

###############################
# Consiste parametro Recebido #
###############################
#
if [ "$#" -lt "1" ]
then
    echo "${nm_programa}.sh: Sintax Error!!!"
    echo "Use.............: ${nm_programa}.sh <ORACLE_SID>"
    exit 1
fi
P_ORACLE_SID=`echo $1 |tr "a-z" "A-Z"`

#######################################
# Verifica se a Copia Esta executando #
#######################################
#
ps -ef |grep "TkAtualizaStandby.sh ${1}" |grep -v $$ |grep -v "sh -c sh" |wc -l 1>/tmp/${nm_programa}.$$
nr_processos=`cat /tmp/${nm_programa}.$$`
rm -f /tmp/${nm_programa}.$$
if [ "${nr_processos}" -gt "0" ]
then
   echo "Atencao: O Processo de Atualizacao esta Executando!!!"
   echo "Tente Novamente mais Tarde!!!"
   echo "Tecle <Enter>  para finalizar"
   read a
   exit 1
fi
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

#
# Limitacao do Contrab a variavel eh atribuida novamente e funcoes
#
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

# Inicializa variaveis de ambiente
F_Inicio $1

# Valida Configuracao do Ambiente
F_Valida_Ambiente

# Ativa o Banco em Modo Read Only
F_Shutdown

# Atualiza Controle de Execucao
F_Controla_Execucao
