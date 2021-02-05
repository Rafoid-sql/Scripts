# Programa   : TkTesteNotifica.sh
# Funcao     : 1) Faz Teste de Notificacao
#
# Autor      : Djalma Luciano Zendron
# Data       : 25/08/2007
# Sintaxe    : sh TkTesteNotifica.sh <Mecanismo de Envio> <Endereco de envio>
# Alterado por :  Djalma Luciano Zendron - Teiko
# .............:  Compatibilidade com RAC
# Data         :  25/08/2007
###############################################################################

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
   # Atibuicao para mostrar os passos na TELA
   set -x
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
      /usr/local/bin/mtmon_evento.pl --severidade=${tk_severidade} --aplicacao=TkStandby --objeto=${nm_programa} --mensagem="${msg}" --dump=${ArqLogProcesso} --eventual --notifica=${MTMON_NOTIFICA} --debug --repete
   fi

   ########################
   # Integracao com FAROL #
   ########################
   if [ "${TkNotifica}" = "FAROL" -a "${STATUS}" = "OK" ]
   then
       sh ${FAROL_HOME}/farolevent.sh --alvo=${nm_alvo} --aplicacao=TkStandby --objeto=${nm_programa} --im=${nm_programa} --severidade=0 --mensagem=\"${msg}\" 1>> ${ArqLogProcesso} 2>> ${ArqLogProcesso}
   elif [ "${TkNotifica}" = "FAROL" -a "${STATUS}" != "OK" ]
   then
       sh ${FAROL_HOME}/farolevent.sh --alvo=${nm_alvo} --aplicacao=TkStandby --objeto=${nm_programa} --im=${nm_programa} --severidade=${tk_severidade} --mensagem=\"${msg}\" --anexo=${ArqLogProcesso} 1>> ${ArqLogProcesso} 2>> ${ArqLogProcesso}
   fi

   # Sai do Laco
   break
done
   
}
########################
# Controle de Execucao #
########################
nm_programa=TkTesteNotifica

###############################
# Consiste parametro Recebido #
###############################
if [ "$#" -lt "1" ]
then
    echo "${nm_programa}.sh: Sintax Error!!!"
    echo "Use.............: ${nm_programa}.sh <ORACLE_SID>"
    exit 1
fi
P_ORACLE_SID=`echo $1 |tr "a-z" "A-Z"`

#############################################
# Verifica se a Atualizacao Esta executando #
#############################################
ps -ef |grep "${nm_programa}.sh ${1}" |grep -v $$ |grep -v "sh -c sh" |wc -l 1>/tmp/${nm_programa}.$$
nr_processos=`cat /tmp/${nm_programa}.$$`

if [ "${nr_processos}" -gt "0" ]
then
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

StringAlvo=`echo ${StringAlvo} |tr "a-z" "A-Z" `
if [ "${StringAlvo}" = "N" ]
then
    nm_alvo=${ORACLE_SID}; export nm_alvo
else
    nm_alvo=${ORACLE_SID}_stdb ; export nm_alvo
fi

##########################
# Variaveis para O Teste #
##########################
tk_severidade=0
STATUS=ERRO
msg="Teste de envio de Notificao via Standby Teiko!!!"
ArqLogProcesso=/tmp/${nm_programa}.$$
trap 'rm -f /tmp/${nm_programa}.$$' 0
echo "
###############################################################################################################
#                                               A T E N C A O                                                 #
###############################################################################################################
Data do Envio...: `date`
	                    <<<<Teste de envio de Notificao via Standby Teiko>>>

###############################################################################################################" >> /tmp/${nm_programa}.$$

#########################
# Funcao de Notificacao #
#########################
F_Notifica "${msg}"
