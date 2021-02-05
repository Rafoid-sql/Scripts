# Programa   : TkAtualizaStandby.sh
# Funcao     : 1) Montar banco Standby
#              2) Aplicar archives
#              3) Abrir banco em read only
#
# Autor      : Djalma Luciano Zendron
# Data       : 25/08/2007
# Sintaxe    : sh TkAtualizaStandby.sh <OracleSid>
# Alterado por :  Djalma Luciano Zendron - Teiko
# .............:  Compatibilidade com RAC
# Data         :  25/08/2007
###############################################################################

F_Inicio(){
####################
# Varivaies Locais #
####################
nm_programa=TkAtualizaStandby
ArqLogProcesso="${DirLog}/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.log"
ArqLogTemp="/tmp/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.$$"
ArqPFILEStandby=${ORACLE_HOME}/dbs/init${ORACLE_SID}.ora
ArqPFILEPrimary="/tmp/init${ORACLE_SID}_`date '+%Y%m%d%H%M%S'`.txt"
ArqExTableSLA="${DirSLA}/RTO_${ORACLE_SID}_`date '+%Y%m%d'`.txt"
ArqExTableTWU="${DirSLA}/TWU_${ORACLE_SID}_`date '+%Y%m%d'`.txt"
ArqDataProducao="${DirTmp}/${ORACLE_SID}_${nm_programa}_TimeProducao.$$"
ArqLogResumo="${DirLog}/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.resumo"
ArqResumoAtu="${DirLog}/${ORACLE_SID}_${nm_programa}.atu"
trap 'rm -f ${ArqLogTemp} /tmp/${nm_programa}.$$ ${DirTmp}/${nm_programa}.$$.initora ${ArqDataProducao}' 0
tk_severidade=0
STATUS=OK
StepCount=0

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
-> Script Shell............. ......................: ${DirBase}/standby/script/${nm_programa}.sh
-> DTU (Delay Time Update) via TkStandbyMenu.......: ${TKDTU_MENU}
-> DTU (Delay Time Update) Default ................: ${TKDTU} Minutios                              " >> ${ArqLogProcesso}
echo "################################ Servidor(es) Primario(os) ###########################################
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

if [ -f "${ArqLockExterno}" ]
then
   STATUS=ERRO
   F_Display   "Encontrou Arquivo de Integração com Outros Software..."
   echo  " ##########################################################################" >> ${ArqLogProcesso}
   echo  " # Atenção: Encontrado o Arquivo (${ArqLockExterno}).                      " >> ${ArqLogProcesso} 
   echo  " #          O processo de atualização do Standby foi CANCELADO!!!          " >> ${ArqLogProcesso}
   echo  " #          Só voltará a executar se o arquivo for removido!               " >> ${ArqLogProcesso}
   echo  " ##########################################################################" >> ${ArqLogProcesso}
   exit 1
fi

if [ -f "${ArqCtlMTCluster}" ]
then
   STATUS=ERRO
   tk_severidade=2 
   F_Display   "Erro, Disparado o Processo de Atualizacao com o Pacote do MTCLUSTER Ativo no servidor Standby"
   F_Display   "Erro, Verifique se o Arquivo de LOCK eh antigo ${ArqCtlMTCLUSTER} "
   F_Notifica  "Erro, Disparado o Processo de Atualizacao com o Pacote do MTCLUSTER Ativo no servidor Standby"
   exit 1
fi
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

if [ ! -f "${ArqParameterIncluirStandby}" ]
then
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro, Nao Encontrado o Arquivo de Parametros a Incluir no Standby."
   F_Display  "-> (${ArqParameterIncluirStandby})"
   F_Notifica "Erro, Nao Encontrado o Arquivo de Parametros a Incluir no Standby."
   exit 1
fi

if [ ! -f "${ArqParameterExcluirStandby}" ]
then
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro, Nao Encontrado o Arquivo de Parametros a Excluir no Standby."
   F_Display  "-> (${ArqParameterIncluirStandby})"
   F_Notifica "Erro, Nao Encontrado o Arquivo de Parametros a Excluir no Standby."
   exit 1
fi


F_Display "Sucesso, Configuracao OK!!!"

}
F_Controla_Atualizacao ()
{
      echo "[`date '+%d/%m/%Y %T'`] Data da Ultima Atualizacao com Sucesso do Standby" > ${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl
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
F_Pre_Atualizacao()
{
#########################################################################
# Preparar os archives disponiveis para serem utilizados na atualizacao #
#########################################################################
STATUS=OK
tk_severidade=0
W_FLAG=0

F_Display "Selecionado os Archives Disponiveis para Atualizacao"
for arq in `ls -rt ${DirArchiveDestCopy}/ |grep .ok 2>>${ArqLogProcesso}`
do
  W_FLAG=1
  mv ${DirArchiveDestCopy}/${arq} ${DirArchiveDestStandby} 2>> ${ArqLogProcesso}
  if [ "$?" != "0" ]
  then
      STATUS=ERRO
      tk_severidade=2
      F_Display  "Erro, no move dos Archives (.ok) para o (${DirArchiveDestStandby})"
  fi 
  while true
  do
   sufixo_arq=`echo $arq |sed -e 's/^.*\././'`

   case $sufixo_arq in
                    .Z) # Sufixo de archives compactados com compress
                        $CMD_UNCOMPRESS ${DirArchiveDestStandby}/${arq} 2>> ${ArqLogProcesso} 
                        if [ "$?" != "0" ]
                        then
                            STATUS=ERRO
                            tk_severidade=2
                            F_Display "Erro na Descompactacao do Archive (${arq})"
                            break
                        fi
                        arq=`echo $arq|sed "s/${sufixo_arq}//"`
                        ;;
                   .gz) # Sufixo de archives compactados com gzip
                        $CMD_GUNZIP ${DirArchiveDestStandby}/${arq} 2>> ${ArqLogProcesso} 
                        if [ "$?" != "0" ]
                        then
                            STATUS=ERRO
                            tk_severidade=2
                            F_Display "Erro na Descompactacao do Archive (${arq})"
                            break
                        fi
                        arq=`echo $arq|sed "s/${sufixo_arq}//"`
                        ;;
                  .bkp) # Sufixo de archives jah salvos para backup
                        arq_sem_sufixo=`echo ${arq} |sed "s/.bkp//"`
                        mv ${DirArchiveDestStandby}/${arq} ${DirArchiveDestStandby}/${arq_sem_sufixo} 2>> ${ArqLogProcesso} 
                        if [ "$?" != "0" ]
                        then
                            STATUS=ERRO
                            tk_severidade=2
                            F_Display "Erro no comando (mv) para retirar sufixo (.bkp) do arquivo (${arq})"
                            break
                        fi
                        arq=`echo $arq|sed "s/${sufixo_arq}//"`
                        ;;
                  .ok) # Sufixo de archives copiado com sucesso
                        arq_sem_sufixo=`echo ${arq} |sed "s/.ok//"`
                        mv ${DirArchiveDestStandby}/${arq} ${DirArchiveDestStandby}/${arq_sem_sufixo} 2>> ${ArqLogProcesso}
                        if [ "$?" != "0" ]
                        then
                            STATUS=ERRO
                            tk_severidade=2
                            F_Display "Erro no comando (mv) para retirar sufixo (.ok) do arquivo (${arq})"
                            break
                        fi  
                        arq=`echo $arq|sed "s/${sufixo_arq}//"`
                        ;;
      ${SufixoArchive}) # Sufixo de archives prontos para serem aplicados
                        break
   esac
 done
done

# Controle de Erro
if [ "${STATUS}" = "ERRO" ]
then
   F_Notifica "Erro na Atualizacao do Banco Standby!"
   exit 1
fi

if [ "${W_FLAG}" = "0" ]
then
   F_Display "Nenhum Archive Novo Selecionado para Atualizacao!"
fi

}

F_Aplica_Archive_Logs(){

##########################################################################################################
## Identificando a ultima sequencia por thread disponivel para ser utilizada no processo de atualizacao. #
##########################################################################################################

F_Display "Identificando a última sequencia de archivelog disponiveis por thread para o processo de atualização."

for id_thread in 1 2 3 4 5 6
do

  w_UltSeqThread=`ls ${DirArchiveDestStandby}/  |grep "${SufixoArchive}"  |grep "${ORACLE_SID}_${id_thread}_" |sort |tail -n1 |cut -f3 -d_ |cut -f1 -d.  2>>${ArqLogProcesso}`
  if [ -z "$w_UltSeqThread" ]
  then
     w_UltSeqThread=0
  else
      ArraySeqThread[${id_thread}]="${w_UltSeqThread}"
      F_Display "Nr. Da Ultima Sequencia disponivel para o processo de atualizacao é...: Thread ${id_thread} -> ${ArraySeqThread[$id_thread]}"
  fi

done


if [ -n "${TKDTU_MENU}" ]
then
   # Quando Executado atualizacao via TkStandbyMenu.sh (Manualmente) Assume o delay ZERO.
   TKDTU="${TKDTU_MENU}"
fi

F_Display "Montando Banco Standby"

$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" > ${ArqLogTemp} 2>&1 <<EOF
shutdown abort
--prompt Nota: Desconsiderar erro de shutdown acima se houver ...
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
startup nomount pfile='${ArqPFILEStandby}'
alter database mount standby database;
quit
EOF

if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=2
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Display "ERRO no comando de startup do standby"
   F_Notifica "Erro no comando de startup do standby"
   exit 1
else
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Display "Sucesso..."
fi

F_Display "Recuperando a Data e Hora do servidor de Producao" 
> ${ArqDataProducao}

i=1
while test ${i} -le ${#hostname_servidor_primario[@]}
do
  ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "date '+%Y%m%d%H%M%S'" 1> ${ArqDataProducao} 2>> ${ArqLogProcesso}
  if [ "$?" = "0" ]
  then
     break
  fi
i=$(($i+1))
done

if [ -s "${ArqDataProducao}" ]
then
    DATA_PROD=`cat ${ArqDataProducao}` 
else
   DATA_PROD="RECOVER COMPLETO" 
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro, Problema para Identificar a Data e Hora no Servidor Primario" 
   F_Display  "Serah executado o recovery completo do Ambiente standby" 
   F_Notifica "Erro, Problema para Identificar a Data e Hora no Servidor Primario" 
fi

F_Display "Aplicando archives"
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set pagesize 0
set linesize 200

DECLARE
  stmt varchar2(200)   :=null;
  RECOVER_WARNING      exception;
  DATA_PROD         varchar(14) := '${DATA_PROD}';
  pragma        exception_init(RECOVER_WARNING ,-01547);
begin
  if DATA_PROD is null then
      stmt:= 'alter database recover automatic standby database';
      execute immediate stmt;
  else
      stmt:='alter database recover automatic standby database until time '||''''||to_char(to_date(DATA_PROD,'YYYYMMDDHH24MISS')-${TKDTU}/1440,'YYYY-MM-DD HH24:MI:SS')||'''';
      execute immediate stmt;
  end if;
  exception 
    when RECOVER_WARNING THEN 
       -- FAZ Recover Completo Para Atender a Primeira Atualizacao do Standby no momento de criacao
        stmt:= 'alter database recover cancel';
        execute immediate stmt;
        stmt:= 'alter database recover automatic standby database';
        execute immediate stmt;
end;
/
quit
EOF

if grep "^ORA-" ${ArqLogTemp}|egrep -v "ORA-00279|ORA-00289|ORA-00280|ORA-00278|ORA-00308|ORA-27037|ORA-06512" 1>>/dev/null 2>> ${ArqLogProcesso}
then
      STATUS=ERRO
      tk_severidade=1
      cat $ArqLogTemp >> $ArqLogProcesso
      F_Display "Erro, Atualizacao Abortada!!!"
      F_Notifica "Erro, Atualizacao Abortada!!!"
      exit 1
else
      ##########################################################################################################
      # Identificando se deu erro em algum arquivo de archivelog e qual a Thread e Sequencia que deu Erro.     #
      # Se o Nr. da Sequencia com erro for menor que o Nr. da Ultima sequencia disponivel para ser utilizada,  #
      # isto pode representar um erro de corrupção ou a falta de uma sequencia de archivelog.                  #
      ##########################################################################################################

      for w_thread_prob in `grep "ORA-00280:" ${ArqLogTemp}  |awk '{print $6i":" $10}'| sed 's/#//g'`
      do
       id_thread=`echo $w_thread_prob |cut -f1 -d:`
       nr_sequence=`echo $w_thread_prob|cut -f2 -d:`
       if [ "${nr_sequence}" -lt "${ArraySeqThread[$id_thread]}" ]
       then
          echo "Nr. Sequence =${nr_sequence} e menor que ${ArraySeqThread[$id_thread]} "
          cat ${ArqLogTemp} >> $ArqLogProcesso
          F_Display "Erro, o archivelog da thread ${id_thread} e sequence number ${nr_sequence} apresentou problema, verifique!!!"
          F_Display "Erro, Atualizacao Abortada!!!"
          F_Notifica "Erro, Atualizacao Abortada!!!"
          exit 1
       fi
      done

      F_Display "Sucesso Sucesso na Atualizacao!!!"
fi

}

F_Controla_SLA()
{
STATUS=OK
tk_severidade=0
# Atualiza o archivo External Table Utilizado para Controlar o SLA
F_Display "Atualizando Controle para SLA"

F_Display "Recuperando a Data e Hora do servidor de Producao"
> ${ArqDataProducao}

i=1
while test ${i} -le ${#hostname_servidor_primario[@]}
do
  ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "date '+%Y%m%d%H%M%S'" 1> ${ArqDataProducao} 2>> ${ArqLogProcesso}
  if [ "$?" = "0" ]
  then
     break
  fi
i=$(($i+1))
done

if [ -s "${ArqDataProducao}" ]
then
    DATA_PROD=`cat ${ArqDataProducao}`
else
   STATUS=ERRO
   tk_severidade=2
   F_Display  "Erro, Problema para Identificar a Data e Hora no Servidor Primario"
   F_Notifica "Erro, Problema para Identificar a Data e Hora no Servidor Primario"
fi

P_RTO_TIME=`echo ${DATA_PROD}`

echo "${P_RTO_ID}:${P_RTO_TIME}" >> ${ArqExTableSLA} 2>> ${ArqLogProcesso}
if [ "${?}" != "0" ]
then
    STATUS=ERRO
    tk_severidade=1
    F_Display  "Erro, Na Atualizacao da External Table de Controle do SLA."
    F_Notifica "Erro, Na Atualizacao da External Table de Controle do SLA."
else
   F_Display "Sucesso..."
fi

if [ "${P_RTO_ID}" = "1" ]
then
   # Soh faz a coleta apos a execucao da Funcao F_Aplica_Archive_Logs, pos o banco fica ativo neste momento.
F_Display "Atualizando Controle para TWU"
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set serveroutput on
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
spool ${ArqResumoAtu}
alter session set optimizer_mode=rule;

select  'LastAchUPDATE:'||THREAD#||':'||sequence#||':'||to_char(first_time,'YYYYMMDDHH24MISS')
from V\$LOGHIST
where (thread#, sequence#) in ( select  THREAD#, max(sequence#)
                                from V\$LOGHIST
                                where first_time >= (select max(resetlogs_time) from v\$database_incarnation) 
                                group by THREAD#)
and first_time >= (select max(resetlogs_time) from v\$database_incarnation)
/
quit
EOF
  if [ "${?}" != "0" ]
  then
      STATUS=ERRO
      tk_severidade=1
      F_Display  "Erro, Na Coleta de dados da External Table de Controle do TWU."
      F_Notifica "Erro, Na Coleta de dados da External Table de Controle do TWU."
  else
     for i in `cat ${ArqLogTemp} |grep "^LastAchUPDATE:" 2>> ${ArqLogProcesso} `
     do
       Stby_thread=`echo $i |cut -f2 -d:`
       Stby_sequence=`echo $i |cut -f3 -d:`
       Stby_first_time=`echo $i |cut -f4 -d:`
       echo "${Stby_thread}:${Stby_sequence}:${Stby_first_time}" >>  ${ArqExTableTWU}
       if [ "$?" != "0" ]
       then
           STATUS=ERRO
           tk_severidade=1
           F_Display  "Erro, Na Atualizacao do Arq. da External Table de Controle do TWU."
           F_Notifica "Erro, Na Atualizacao do Arq. da External Table de Controle do TWU."
       else
           F_Display "Sucesso..."
       fi
     done
  fi
fi
}

F_Report ()
{

F_Display "Ativando Banco em modo READ ONLY"

$ORACLE_HOME/bin/sqlplus -s "/ as  sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set linesize 132
col HOST_NAME format a20
alter database open read only;
connect / as sysdba
show user
Prompt ---------------------------Dados do Banco Standby--------------------------------------------

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
select  'Nro do Archive Log Corrente na Instance ('||THREAD#||') => '|| max(sequence#)
from V\$LOGHIST
where first_time >= (select max(resetlogs_time) from v\$database_incarnation)
group by THREAD# order by THREAD#;

select distinct 'Data de atualizacao do Banco Standby    => ' ||to_Char(checkpoint_time,'DD-MON-YYYY HH24:MI:SS')
from V\$DATAFILE_HEADER;
Prompt ---------------------------------------------------------------------------------------------

quit
EOF

if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=1
   F_Display "ERRO"
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Notifica "Erro na ativacao do banco standby em modo read only"
   exit 1
else
   cat $ArqLogTemp >> $ArqLogProcesso
   # Gera Arquivo de Resumo Para Ser enviado ao Cliente, quando este nao estiver integrado com o Monitoramento Teiko.
   echo "############################################################################################"  > ${ArqLogResumo}
   echo "#        R E S U M O   D E   A T U A L I Z A C A O   D O   B A N C O   S T A N D B Y       #" >> ${ArqLogResumo}
   echo "############################################################################################" >> ${ArqLogResumo}
   echo "                                                                                            " >> ${ArqLogResumo}
   echo "Nota: Veja no rodapé a data de Atualização do Seu banco Standby.                            " >> ${ArqLogResumo}
   echo "                                                                                            " >> ${ArqLogResumo}
   echo "Importante:                                                                                 " >> ${ArqLogResumo}
   echo "- Você deve receber um resumo via email diariamente!                                        " >> ${ArqLogResumo}
   echo "- Caso você não receba este email diariamente entre em contato com o Suporte Teiko, visando " >> ${ArqLogResumo}
   echo "  verificar se o banco Standby esta sendo atualizado corretamente!                          " >> ${ArqLogResumo}
   echo "############################################################################################" >> ${ArqLogResumo}
   cat ${ArqLogTemp} >> ${ArqLogResumo}
   F_Display "Sucesso..."
fi
}


F_Pos_Atualizacao ()
{

F_Display "Selecionando Archives que nao Seram Mais Necessarios!!!"
$ORACLE_HOME/bin/sqlplus -s "/ as  sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set linesize 132
set pagesize 0
set feedback off
set termout off
select  'ARCHIVES_LIBERADOS:'||THREAD#||':'||(max(sequence#)-1)
from V\$LOGHIST
where first_time >= (select max(resetlogs_time) from v\$database_incarnation)
group by THREAD# order by THREAD#;
quit
EOF
if [ "$?" != "0" ]
then
   STATUS=ERRO
   tk_severidade=2
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Display  "Erro Selecao dos Archives que nao Seram Mais Necessarios!!!"
   F_Notifica "Erro Selecao dos Archives que nao Seram Mais Necessarios!!!"
   exit 1
else
   F_Display "Sucesso..."
fi

STATUS=OK
w_STATUS=OK
tk_severidade=0

for ArchLib in `cat ${ArqLogTemp} |grep "^ARCHIVES_LIBERADOS:" `
do
  NrThreadLib=`echo ${ArchLib}|cut -f2 -d:`
  NrArchLib=`echo ${ArchLib}|cut -f3 -d:`
   
  # Tratamento dos Archives por Thread
  #for ArchStby in `ls -rt ${DirArchiveDestStandby}/ |grep "^arch_${NrThreadLib}_"|grep ${SufixoArchive} 2>>${ArqLogProcesso}` 
  for ArchStby in `ls -rt ${DirArchiveDestStandby}/ |grep "^${ORACLE_SID}_${NrThreadLib}_"|grep ${SufixoArchive} 2>>${ArqLogProcesso}` 
  do
   NrArchStby=`echo ${ArchStby} |cut -f3 -d_|cut -f1 -d.`
   if [ ${NrArchStby} -le ${NrArchLib} ] 
   then
      if [ "${RemoveArchive}" = "APLICADO"  ]
      then
          F_Display "Removendo Archive (${DirArchiveDestStandby}/${ArchStby}) no Standby!!!"
          rm -f ${DirArchiveDestStandby}/${ArchStby} 2>> ${ArqLogProcesso}
          if [ "$?" != "0" ]
          then
             STATUS=ERRO
             tk_severidade=1
             F_Display "Aviso, Problema Na remocao do Archive no Standby!!!"
          fi
          F_Display "Removendo Archive no Site Primario!!!"
          i=1
          while test ${i} -le ${#hostname_servidor_primario[@]}
          do
            F_Display "Removendo Archive (${DirArchiveDestPrimario[$i]}/${ArchStby}) no Servidor (${hostname_servidor_primario[$i]}) !!!"
            ssh ${cmd_opcao} "${hostname_servidor_primario[$i]}" "rm -f  ${DirArchiveDestPrimario[$i]}/${ArchStby}*" 1>> ${ArqLogProcesso} 2>> ${ArqLogProcesso}
            if [ "$?" = "0" ]
            then
               if [ "${w_STATUS}" = "OK" ]
               then
                  w_STATUS=OK
               fi
            else
               w_STATUS=ERRO
            fi
          i=$(($i+1))
          done
          if [ "${w_STATUS}" != "OK" ]
          then
             # -- Indica que houve um archive que nao pode ser removido em algum dos sites primarios!!!
             STATUS=ERRO
             tk_severidade=1
          fi
      else
          F_Display "Compactando Archive (${DirArchiveDestStandby}/${ArchStby})"
          ${CMD_Compacta} ${DirArchiveDestStandby}/${ArchStby} 2>> ${ArqLogProcesso}
          if [ "$?" = "0" ]
          then
              ArchStby=${ArchStby}${SufixoCompactador}
          else
              STATUS=ERRO
              tk_severidade=1 
          fi
          F_Display "Movendo Archive para (${DirArchiveDestApplied})."
          mv ${DirArchiveDestStandby}/${ArchStby} ${DirArchiveDestApplied} 2>> ${ArqLogProcesso}
          if [ "${?}" != "0" ] 
          then
             STATUS=ERRO
             tk_severidade=1
             F_Display  "Aviso, Problema no move do Archive!"
          fi
      fi
   fi
  done
done
# Controle de Erro
if [ "${STATUS}" = "ERRO" ]
then
   F_Notifica "Aviso, Problema na Funcao Pos-Atualizacao do Standby!"
fi

if [ "${OPEN_READ_ONLY}" = "N" ] || \
   [ "${OPEN_READ_ONLY}" = "n" ]
then

F_Display "Desativando banco Standby"

$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off
shutdown immediate
quit
EOF

   if [ "$?" != "0" ]
   then
      STATUS=ERRO
      tk_severidade=1
      cat $ArqLogTemp >> $ArqLogProcesso
      F_Display  "ERRO no comando de shutdown do standby"
      F_Notifica "Erro no comando de shutdown do standby"
   else
      cat $ArqLogTemp >> $ArqLogProcesso
      F_Display "Sucesso..."
   fi
fi
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
    F_Display "Copiando o SPFILE do servidor Primário Para Copiar o PFILE para o Standby!!!"
    i=1
    while test ${i} -le ${#hostname_servidor_primario[@]}
    do
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


########################
# Controle de Processo #
########################
# Varivaies Locais
nm_programa=TkAtualizaStandby

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

# Atualiza Arquivos com Controle de SLA
# com Inicio da Atualizacao
P_RTO_ID=0
F_Controla_SLA

# Valida Configuracao do Ambiente
F_Valida_Ambiente

# Gera PFILE para startup do Standby
F_GeraPFILE

# Tratamento dos Archives Disponiveis para Atualizacao
F_Pre_Atualizacao

# Atualizacao do Standby
F_Aplica_Archive_Logs

# Atualiza integracao com o MTMON
F_Controla_Atualizacao

# Relatorio de Atualizacao
F_Report

# Atualiza Arquivos com Controle de SLA
# com Fim de atualizacao
P_RTO_ID=1
F_Controla_SLA

# Tratamento dos Archives Atualizados
F_Pos_Atualizacao

# Atualiza Controle de Execucao
F_Controla_Execucao

F_Display "Fim da Atualizacao com Sucesso!!!"


