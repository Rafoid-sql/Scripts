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
ArqPFILEStandby=${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora
ArqPFILEPrimary="/tmp/init${ORACLE_SID}_`date '+%Y%m%d%H%M%S'`.txt"
trap 'rm -f ${ArqPFILEPrimary} ${ArqLogTemp} ' 0

STATUS=OK
StepCount=0

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
-> Diretorio Arc. Copiados ........................: ${DirArchiveDestCopy} 
-> Diretorio Arc. Prontos para Aplicar ............: ${DirArchiveDestStandby} 
-> Diretorio Arc. Jah Aplicados ...................: ${DirArchiveDestApplied}  
-> Script Shell............. ......................: ${DirBase}/standby/script/${nm_programa}.sh       
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

F_Controla_Execucao ()
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
tk_severidade=0

F_Display "Verificando Configuracao do Ambiente Standby" 

if [ "`hostname`" != "$hostname_servidor_standby" ]
then
    STATUS=ERRO
    tk_severidade=1
    F_Display      "Erro, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    F_Notifica     "Aviso, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    echo           "Erro, Atencao: Voce NAO esta no servidor standby ($hostname_servidor_standby)!!!"
    echo           "Digite <Enter> Para Retornar ao Menu!"
    read
    exit 1
fi

if [ -f "${DirTmp}/${ORACLE_SID}_AtivaStandbyReadWrite.lock" ]
then
   STATUS=ERRO
   tk_severidade=1
   F_Display      "Atencao: O Processo Que Ativa o Banco em Modo (Read Write) jah esta em Andamento."
   F_Display      ".......: Verifique se o Arquivo de LOCK eh antigo (${DirTmp}/${ORACLE_SID}_AtualizaStandbyReadWrite.lock)"
   F_Notifica     "Aviso, Executado o Processo que Ativa o Banco em Modo (Read Write) com este jah em Andamento!"
   echo           "Atencao: Encontrato o Arquivo (${DirTmp}/${ORACLE_SID}_AtualizaStandbyReadWrite.lock) o que indica que"
   echo           "         o Banco esta em processo de Startup em Modo (Read Write). "
   echo           "         Voce nao pode Iniciar o Banco em (Read Only) com este processo sendo Executado!"
   echo           "         Entre em Contato com o Administrador de Banco de Dados (DBA)." 
   echo           "Digite <Enter> Para Retornar ao Menu!"
   read a
   exit 13
fi

if [ -f "${ArqCtlMTCLUSTER}" ]
then
   STATUS=ERRO
   tk_severidade=1
   F_Display      "Atencao: O Processo Que Ativia o Banco em Modo (Read Write) foi executado com o Pacote do MTCLUSTER Ativo no servidor Standby"
   F_Display      ".......: Verifique se o Arquivo de LOCK eh antigo ${ArqCtlMTCLUSTER} "
   F_Notifica     "Aviso, O Processo Que Ativa o Banco em Modo (Read Write) foi executado com o Pacote do MTCLUSTER Ativo no servidor Standby"
   echo           "Atencao: Encontrato o Arquivo (${ArqCtlMTCLUSTER}), o que indica que o Pacote MTCLUSTER esta Ativo no Servidor Standby."
   echo           "         Voce nao pode Iniciar o Banco em (Read Only) com este processo sendo Executado!" 
   echo           "Digite <Enter> Para Retornar ao Menu!"
   read a
   exit 14
fi

F_Display "Sucesso, Configuracao OK!!!"

}

F_GeraPFILE(){

STATUS=OK
tk_severidade=0
w_flag=9999
#########################################
# Gerando PFILE COM BASE NA PRODUCAO #
#########################################

F_Display "Gerando PFILE no Servidor Primario!"

$ORACLE_HOME/bin/sqlplus -s "${stringconnect} as sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
create pfile='${ArqPFILEPrimary}' from spfile;
quit
EOF

if [ "$?" != "0" ]
then
    STATUS=ERRO
    tk_severidade=1
    F_Display "Erro na Gerando PFILE no Servidor Primario!"
    cat ${ArqLogTemp} >> ${ArqLogProcesso}
else
    F_Display  "Sucesso na Geracao..."
    #####################################################
    # Copia do SPFILE de Producao para ambiente Standby #
    #####################################################
    F_Display "Verificando a disponibilidade do(s) servidor(es) Primario(s) Para Copiar o PFILE para o Standby!!!"
    i=1
    while test ${i} -le ${#hostname_servidor_primario[@]}
    do
            # Faz a copia do SPFILE do servidor Primario para o Standby.
            echo "Copiando o PFILE do Servidor Primario (${hostname_servidor_primario[$i]})!" > ${ArqLogTemp}
            scp ${cmd_opcao} ${hostname_servidor_primario[$i]}:${ArqPFILEPrimary} /tmp/ 1>> ${ArqLogTemp} 2>> ${ArqLogTemp}
            if [ "${?}" = "0" ]
            then
               ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "rm -f  ${ArqPFILEPrimary}" 2>> ${ArqLogProcesso}
               w_flag=0
               # Copia com sucesso
               break
            else
                STATUS=ERRO
                tk_severidade=1
                echo "Aviso, Problema na Copia do PFILE do Servidor Primario!" >> ${ArqLogTemp}
            fi 
    i=$(($i+1))
    done
fi

if [ "${w_flag}" != "0" ]
then
    cat ${ArqLogTemp} >> ${ArqLogProcesso}
    F_Notifica "Erro, Na Geracao no PFILE no Servidor Primario!!!"
else
    F_Display "Executando Rename do PFILE!!!"
    mv ${ArqPFILEPrimary} ${ArqPFILEStandby} 1>>${ArqLogProcesso} 2>>${ArqLogProcesso}
    if [ "${?}" != "0" ]
    then
        w_flag=9999
        F_Notifica "Erro, Na Geracao no PFILE no Servidor Primario!!!"
    fi
fi

########################################
# Gerando INIT.ORA COM BASE NO STANDBY #
########################################
if [ "${w_flag}" != "0" ]
then
    F_Display "Gerando PFILE com base no Servidor Standby!"
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
create pfile='${ArqPFILEStandby}' from spfile;
quit
EOF

   if [ "$?" != "0" ]
   then
      STATUS=ERRO
      tk_severidade=2
      cat ${ArqLogTemp} >> ${ArqLogProcesso}
      F_Display  "Erro, Na Geracao do PFILE no Servidor Standby"
      F_Notifica "Erro, Na Geracao no PFILE no Servidor Standby"
      exit 1
   else
      F_Display  "Sucesso na Geracao..."
   fi
fi

F_Display "Excluindo os Parametros Abaixo"
echo "--------------------------------------------------------------------------" >> ${ArqLogProcesso}
cat ${ArqParameterExcluirStandby} >> ${ArqLogProcesso}
echo "--------------------------------------------------------------------------" >> ${ArqLogProcesso}

############################################################################################
# Relacao de parametros que serao retirados do init principal para gerar o init do standby #
############################################################################################
egrep -v -i -f ${ArqParameterExcluirStandby} ${ArqPFILEStandby} 1> ${DirTmp}/${ORACLE_SID}_${nm_programa}.$$.initora 2>>${ArqLogProcesso}
mv ${DirTmp}/${ORACLE_SID}_${nm_programa}.$$.initora ${ArqPFILEStandby} 2>>${ArqLogProcesso}
if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro na Exclusao de Parametros do Arquivo PFILE do Standby"
   F_Notifica "Erro na Exclusao de Parametros do Arquivo PFILE do Standby"
   exit 1 
fi

F_Display "Incluindo os Parametros Abaixo"
echo "--------------------------------------------------------------------------" >> ${ArqLogProcesso}
cat ${ArqParameterIncluirStandby} >> ${ArqLogProcesso}
echo "--------------------------------------------------------------------------" >> ${ArqLogProcesso}

##################################################################
# Relacao de parametros que serao adicionados no init do standby #
##################################################################

cat ${ArqParameterIncluirStandby} >> ${ArqPFILEStandby} 2>>${ArqLogProcesso}
if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro na Inclusao de Parametros do Arquivo PFILE do Standby"
   F_Notifica "Erro na Inclusao de Parametros do Arquivo PFILE do Standby"
   exit 1 
fi
F_Display "Fim das Atualizacao do PFILE" 
}



F_AtivaReadOnly()
{

F_Display "Ativando Banco em modo READ ONLY"
echo  "Ativando Banco em modo READ ONLY"

$ORACLE_HOME/bin/sqlplus -s "/ as  sysdba" <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 300
set linesize 132
set feedback off
set termout off
col HOST_NAME format a20
startup nomount pfile='${ArqPFILEStandby}'
alter database mount standby database;
alter database open read only;
select INSTANCE_NAME,
       STATUS,
       DATABASE_STATUS,
       HOST_NAME,
       VERSION
from V\$INSTANCE;

select NAME,
       CREATED,
       OPEN_MODE
from V\$DATABASE;

set pagesize 0
set feedback off
set termout off
prompt
select  'Nro do Archive Log Corrente na Instance ('||THREAD#||') => '|| max(sequence#)
from V\$LOGHIST
where  first_time >= (select max(resetlogs_time) from v\$database_incarnation)
group by THREAD# order by THREAD#;
select distinct 'Data de atualizacao do Banco           => ' ||to_Char(checkpoint_time,'DD-MON-YYYY HH24:MI:SS')
from V\$DATAFILE_HEADER;
quit
EOF
if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro, No Processo Que Ativa o Banco Standby em modo READ ONLY!"
   F_Notifica "Erro, No Processo Que Ativa o Banco Standby em modo READ ONLY!"
   echo " 
Fim do processo Com Erro!!! 

Tecle <Enter>  para finalizar"
read a
exit 1
else
   F_Display  "Sucesso..."
   echo " 
Fim do processo !!! 

Efetue acesso ao banco de dados Standby e verifique se esta ok.
Tecle <Enter>  para finalizar"
read a
fi
}
########################
# Controle de Processo #
########################
# Varivaies Locais
nm_programa=TkAtivaStandbyReadOnly

################################
# Consiste parametro Recebido  #
################################
if [ "$#" -lt "1" ]
then
    echo "${nm_programa}.sh: Sintax Error!!!"
    echo "Use.............: TkAtivaStandbyReadOnly.sh <ORACLE_SID>"
    exit 1
fi
P_ORACLE_SID=`echo $1 |tr "a-z" "A-Z"`

#######################################
# Verifica se a Copia Esta executando #
#######################################
ps -ef |grep "TkAtualizaStandby.sh ${1}" |grep -v $$ |grep -v "sh -c sh"|wc -l 1>/tmp/${nm_programa}.$$
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

#
# Ativa Modo Silence/quiet do ssh e scp
#
UsarOpcaoSilence=`echo ${UsarOpcaoSilence} |tr "a-z" "A-Z" `

if [ "${UsarOpcaoSilence}" = "S" ]
then
   cmd_opcao=" -q " ; export cmd_opcao
fi



# Inicializa variaveis de ambiente
F_Inicio $1

# Valida Configuracao do Ambiente
F_Valida_Ambiente

# Gera PFILE para startup do Standby
F_GeraPFILE

# Ativa o Banco em Modo Read Only
F_AtivaReadOnly

# Atualiza Controle de Execucao
F_Controla_Execucao

