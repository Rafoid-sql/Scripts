# Programa   : TkCheckSLA.sh
# Funcao     : 1) Previnir a violacao de SLA
#
# Autor      : Djalma Luciano Zendron
# Data       : 25/08/2007
# Sintaxe    : sh TkCheckSLA.sh <OracleSid>
# Alterado por :  Djalma Luciano Zendron - Teiko
# .............:  Compatibilidade com RAC
# Data         :  25/08/2007
###############################################################################

F_Inicio(){

####################
# Varivaies Locais #
####################
nm_programa=TkCheckSLA
ArqLogProcesso="${DirLog}/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.log"
ArqLogTemp="/tmp/${ORACLE_SID}_${nm_programa}_`date '+%Y%m%d'`.$$"
ArqLogResumo="${DirLog}/${ORACLE_SID}_${nm_programa}_Resumo_`date '+%Y%m%d'`.log"
ArqLogResumoAtu="${DirLog}/${ORACLE_SID}_TkAtualizaStandby_`date '+%Y%m%d'`.resumo"
ArqDataProducao="${DirTmp}/${ORACLE_SID}_${nm_programa}_TimeProducao.$$"
trap 'rm -f ${ArqLogTemp} ${ArqDataProducao} ' 0
tk_severidade=0
STATUS=OK
StepCount=0
#######################################
# Verifica se a Copia Esta executando #
#######################################
ps -ef |grep "${nm_programa}.sh ${1}" |grep -v $$ |grep -v "sh -c sh" |wc -l 1>/tmp/${nm_programa}.$$
nr_processos=`cat /tmp/${nm_programa}.$$`
rm -f /tmp/${nm_programa}.$$
if [ "${nr_processos}" -gt "0" ]
then
   F_Display "Atencao: O Processo de ${nm_programa} Executando!!!" 
   F_Display "Tente Novamente mais Tarde!!!"
   exit 1
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
-> Script Shell............. ......................: ${DirBase}/standby/script/${nm_programa}.sh
-> RPO (Recovery Point Objetive) ..................: ${TKRPO} Minutios                              
-> RTO (Recovery Time Objetive) ...................: ${TKRTO} Minutios                              
-> TWU (Time Without Update) ......................: ${TKTWU} Minutios                              
-> DTU (Delay Time Update).........................: ${TKDTU} Minutios                              " >> ${ArqLogProcesso}
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

F_Display "Sucesso, Configuracao OK!!!"

}

F_Controla_Execucao()
{
   echo "[`date '+%d/%m/%Y %T'`] Data da Ultima Atualizacao com Sucesso do Standby" > ${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl
   if [ "$?" != "0" ]
   then
          F_Display "Problema na atualizacao do arquivo ctl (${DirMtmon}/${ORACLE_SID}_${nm_programa}.ctl)"
   fi
   
   if [ "${TkNotifica}" = "FAROL" -a "${STATUS}" = "OK" ]
   then
      F_Display "Enviando status do CheckSLA para o FAROL."
      F_Notifica "Sucesso na conferencia de SLA!!!"
   fi
}  

F_Notifica ()
{
   # Parametro $*: subject do email
   msg="Banco(${ORACLE_SID}) - $*"

if [ "${w_flag_resumo}" -eq 1 ]
then
   ArqAnexo=${ArqLogResumo} 
else
   ArqAnexo=${ArqLogProcesso}
fi

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
      mtsend.pl --email $email_destino_log --subject "$cliente-$nm_programa-$msg" --attach $ArqAnexo 1>>/dev/null
   elif [ "${TkNotifica}" = "MTSEND" -a "${STATUS}" != "OK" ]
   then
      mtsend.pl --email $email_destino_erro --subject "$cliente-$nm_programa-$msg" --attach $ArqAnexo 1>>/dev/null
   fi

   #######################
   # Integracao com MUTT #
   #######################
   if [ "${TkNotifica}" = "MUTT" -a "${STATUS}" = "OK" ]
   then
      mutt -a $ArqAnexo -s "$cliente-$nm_programa-$msg" $email_destino_log </dev/null
   elif [ "${TkNotifica}" = "MUTT" -a "${STATUS}" != "OK" ]
   then
      mutt -a $ArqAnexo -s "$cliente-$nm_programa-$msg" $email_destino_erro < /dev/null
   fi

   ########################
   # Integracao com MAILX #
   ########################
   if [ "${TkNotifica}" = "MAILX" -a "${STATUS}" = "OK" ]
   then
      (echo "Favor Verificar Anexo\!\!\!"; uuencode  $ArqAnexo $ArqAnexo ) |mailx -s "$cliente-$nm_programa-$msg" $email_destino_log </dev/null >>/dev/null
   elif [ "${TkNotifica}" = "MAILX" -a "${STATUS}" != "OK" ]
   then
      (echo "Favor Verificar Anexo\!\!\!"; uuencode  $ArqAnexo $ArqAnexo ) |mailx -s "$cliente-$nm_programa-$msg" $email_destino_log </dev/null >>/dev/null
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
F_Transfere_Arq_SLA()
{
STATUS=OK
tk_severidade=0
i=1
while test ${i} -le ${#hostname_servidor_primario[@]}
do
    if [ -s "${ArqExTableSLA}" ]
    then
        F_Display "Transferindo o Arq. para o Servidor (${hostname_servidor_primario[$i]})"
        scp ${cmd_opcao} ${ArqExTableSLA} ${hostname_servidor_primario[$i]}:${DirArchiveDestPrimario[$i]}/${NmArqExTable} 2>> ${ArqLogProcesso}
        if [ "$?" != "0" ]
        then
           STATUS=ERRO
           tk_severidade=1
        fi
     else
          STATUS=ALERT
          F_Display "Aviso, Arq. de Controle (${ArqExTableSLA}) nao Encontrado!!!"
    fi
i=$(($i+1))
done

#############################################
# Notifica A Ocorrencia de Erros Se Existir #
#############################################
if [ "$STATUS" = "OK" ]
then
    F_Display "Sucesso na Transferencia."
elif [ "$STATUS" = "ALERT" ]
then
    F_Display     "Nenhum Arquivo de Controle de SLA foi Transferido para o(s) Site(s) Primario(s)!"
    F_Display     "Serah Utilizado a posicao da Ultima Transferencia com sucesso!"
else
    F_Display     "Erro, Problema Na Transferencia dos Arq. de Controle de SLA para o(s) Site(s) Primario(s)!"
    F_Notifica    "Erro, Problema Na Transferencia dos Arq. de Controle de SLA para o(s) Site(s) Primario(s)!"
    exit 1
fi

}

F_Controla_SLA ()
{

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

F_Display "Montado Clausula Where para Validacao das tablespace em Force Logging!"
if [ -s "${TKListaTbsSemMonitaramento}" ]
then
  for i in `echo ${TKListaTbsSemMonitaramento}`
  do
    add_where_force=${add_where_force} AND  TABLESPACE_NAME <> '$i'
  done 
fi

F_Display "Verificando os indicadores de SLA (RPO,RTO e TWU)"
$ORACLE_HOME/bin/sqlplus -s "${stringconnect}" > ${ArqLogTemp} 2>&1 <<EOF
whenever sqlerror exit sql.sqlcode ;
set serveroutput on
set tab off
set pagesize 0
set linesize 80
set feedback off
set termout off

alter session set optimizer_mode=rule ;

Select ''||chr(10)||
       'Ultimos Archives em cada Site'||chr(10)||
       '=============================' from dual;
select 'Site Standby-> '||SITE_STANDBY.THREAD#||' - '||SITE_STANDBY.SEQUENCE#||' - '||to_char(SITE_STANDBY.TIME_REPLICATION,'YYYY/MM/DD HH24:MI:SS')||chr(10)||
       'Site Primary-> '||SITE_PRIMARY.THREAD#||' - '||SITE_PRIMARY.SEQUENCE#||' - '||to_char(SITE_PRIMARY.NEXT_TIME,'YYYY/MM/DD HH24:MI:SS')||chr(10)
from (select thread#,sequence#,time_replication
        from TK_RPO_TABLE_CONTROL
       where (thread#,sequence#) in (select t2.thread#,max(t2.sequence#)
                                       from TK_RPO_TABLE_CONTROL T2,
                                            GV\$THREAD           T1
                                      WHERE T1.THREAD#  = T2.THREAD#
                                       group by t2.thread#)) SITE_STANDBY,
     (select distinct thread#,sequence#,next_time
        from GV\$ARCHIVED_LOG
       where (thread#,sequence#) in (select  t2.thread#,max(t2.sequence#)
                                     from GV\$ARCHIVED_LOG t2,
                                          GV\$THREAD       T1
                                      WHERE T1.THREAD#  = T2.THREAD#
                                       and  t2.resetlogs_time >= (select max(resetlogs_time) from v\$database_incarnation)
                                     group by t2.thread#)) SITE_PRIMARY
where site_standby.thread# = site_primary.thread#
/

Select ''||chr(10)||
       'RPO dos Archives Jah Transferidos'||chr(10)||
       '=================================' from dual;
select distinct('Recovery_Point_Objetive:'||T1.THREAD#||':'||T1.sequence#||':'||round(((T1.TIME_REPLICATION-T2.NEXT_TIME)*1440)))
from TK_RPO_TABLE_CONTROL T1,
     GV\$ARCHIVED_LOG     T2,
     GV\$THREAD           T3
where t1.time_replication > (select TIME_CONFERENCE from  TK_SLA_CONTROL)
and   t1.thread# = t2.Thread#
and   t2.thread# = t3.thread#
and   t1.sequence# = t2.sequence#
and   T2.creator = 'ARCH'
and   t2.resetlogs_time >= (select max(resetlogs_time) from v\$database_incarnation)
/

Select ''||chr(10)||
       'RPO dos Archives Nao Transferidos'||chr(10)||
       '=================================' from dual;
select distinct ('Recovery_Point_Objetive:'||T1.THREAD#||':'||T1.sequence#||':'||round(((sysdate-t1.next_time)*1440)))
from  (select THREAD#,Sequence#,next_time,creator
       from Gv\$Archived_log 
       where resetlogs_time >= (select max(resetlogs_time) from v\$database_incarnation)) T1,
      (select t1.thread#,max(t1.sequence#) sequence#
       from TK_RPO_TABLE_CONTROL t1,
            GV\$THREAD            t2
       where t1.thread# = t2.thread#
       group by t1.thread#) t2
where t1.thread# = t2.thread#
and   t1.sequence# > t2.sequence#
and   t1.creator = 'ARCH'
and   t1.next_time > (select TIME_CONFERENCE from  TK_SLA_CONTROL)
/

select '' from dual;
select  'TWU do Database por THREAD#'||chr(10)||
        '===========================' from dual;
select distinct('TWU Por THREAD#:'||SITE_PRIMARY.THREAD#||':'||SITE_PRIMARY.sequence#||':'||round(((sysdate - SITE_PRIMARY.NEXT_TIME)*1440)))
from ( select thread#,sequence#,next_time
          from Gv\$archived_log
          where (thread#,sequence#) in (select t1.THREAD#, Max(T1.Sequence#) 
                                         from Gv\$Archived_log  t1,
                                              gv\$thread        t2
                                        where t1.thread# = t2.thread# 
                                        and  t1.creator  = 'ARCH' 
                                        and  t1.resetlogs_time >= (select max(resetlogs_time) from v\$database_incarnation)
                                        group by t1.thread#)
            and creator = 'ARCH' ) SITE_PRIMARY,
     ( select thread#,sequence#,time_current
         from  TK_TWU_TABLE_CONTROL
         where (thread#,sequence#) in (select t1.THREAD#, Max(t1.Sequence#) 
                                        from   TK_TWU_TABLE_CONTROL t1,
                                               GV\$thread           T2
                                       WHERE   T1.THREAD# = T2.THREAD#
                                        group by t1.thread#)) SITE_STANDBY
where site_primary.thread# =  site_standby.thread#
and   site_primary.sequence# > site_standby.sequence#
/

Select ''||chr(10)||
       'Maior TWU do Standby'||chr(10)||
        '====================' from dual;
select max(distinct('TimeSemUpdate:'||round(((SITE_PRIMARY.NEXT_TIME-SITE_STANDBY.TIME_CURRENT)*1440))))
    --   distinct('TimeSemUpdate:'||SITE_PRIMARY.THREAD#||':'||SITE_PRIMARY.sequence#||':'||round(((SITE_PRIMARY.NEXT_TIME-SITE_STANDBY.TIME_CURRENT)*1440)))
    --   ,SITE_PRIMARY.thread#, SITE_PRIMARY.sequence#, to_char(SITE_PRIMARY.next_time,'YYYY/MM/DD HH24:MI:SS')
    --   ,SITE_STANDBY.thread#, SITE_STANDBY.sequence#, to_char(SITE_STANDBY.time_current,'YYYY/MM/DD HH24:MI:SS')
from ( select thread#,sequence#,next_time
          from Gv\$archived_log
          where (thread#,sequence#) in (select t1.THREAD#, Max(t1.Sequence#) 
                                        from Gv\$Archived_log  t1,
                                             Gv\$thread        t2
                                        where t1.thread# = t2.thread#
                                        and t1.creator= 'ARCH' 
                                        and t1.resetlogs_time >= (select max(resetlogs_time) from v\$database_incarnation)
                                        group by t1.thread#)
            and creator = 'ARCH' ) SITE_PRIMARY,
     ( select thread#,sequence#,time_current
         from  TK_TWU_TABLE_CONTROL
         where (thread#,sequence#) in (select t1.THREAD#, Max(t1.Sequence#) 
                                         from TK_TWU_TABLE_CONTROL T1,
                                              gv\$thread           T2
                                        WHERE T1.THREAD#  = T2.THREAD#
                                        group by t1.thread#)) SITE_STANDBY
--where site_primary.thread# =  site_standby.thread#
/

DECLARE
   DT_BEGIN date  :=null;
   DT_END   date  :=null;
   DATA_PROD     varchar(14) := '${DATA_PROD}';

BEGIN
    -- Identifica a data de Inicio da atualizacao
    select max(TIME_UPDATE) INTO DT_BEGIN
      from TK_RTO_TABLE_CONTROL 
     where id_action = 0;
     dbms_output.put_line('Begin ->'||to_char(DT_BEGIN,'YYYY/MM/DD HH24:MI:SS'));   

     if DT_BEGIN is null then
        DT_BEGIN := (sysdate-1);
     end if;

    -- Identifica a data de Fim da Atualizacao
    select max(TIME_UPDATE) INTO DT_END
      from TK_RTO_TABLE_CONTROL 
     where id_action = 1
       and TIME_UPDATE > DT_BEGIN;

     dbms_output.put_line('END   ->'||to_char(DT_END,'YYYY/MM/DD HH24:MI:SS'));   

     if DT_END is null then
        DT_END := to_date(DATA_PROD,'YYYYMMDDHH24MISS');
     end if;
    
    -- Gera o output com o RTO
    DBMS_OUTPUT.PUT_LINE('RTO do Database');
    DBMS_OUTPUT.PUT_LINE('==============='||chr(10));
    DBMS_OUTPUT.PUT_LINE('Recovery_Time_Objetive:'||round(((DT_END - DT_BEGIN)*1440)));
END;
/
select '' from dual;

Update TK_SLA_CONTROL 
set TIME_CONFERENCE = sysdate
/

commit;

select 'MonitorForceLogging:'||tablespace_name||':'||force_logging
  from sys.dba_tablespaces 
 where contents not in ('UNDO','TEMPORARY')
   and force_logging <> 'YES'
${add_where_force}
/

quit
EOF
#
# Consistencia de Erro Implementada em funcao da Versao 10g R1 na Unimed Litoral
# Serah removida no futuro.
if [ "$?" != "0" ]
then
   if grep  "^ORA-" ${ArqLogTemp} 1>>/dev/null 2>>/dev/null
   then
       STATUS=ERRO
       tk_severidade=2
       cat $ArqLogTemp >> $ArqLogProcesso
       F_Display  "Erro, Na identificao dos indicadores de SLA (RPO, RTO e TWU)."
       F_Notifica "Erro, Na identificao dos indicadores de SLA (RPO, RTO e TWU)."
       exit 1
   fi
else
   cat $ArqLogTemp >> $ArqLogProcesso
   F_Display "Sucesso..."
fi

#
# Valida tablespace SEM FORCE_LOGGING
#
if grep "^MonitorForceLogging:" ${ArqLogTemp} 1>>/dev/null 2>>/dev/null 
then
   F_Display "Erro, Existem tablespace Criados sem a opcao FORCE_LOGGING ativa" 
   F_Display "Todos os Objetos desta tablespaces devem ser recriados, apos a tablespace ser alterada para FORCE_LOGGING"
   F_Display "Veja a Lista abaixo:"
   echo "-----------------------------------------------------------------------------" >> ${ArqLogProcesso}
   cat ${ArqLogTemp} |grep  "^MonitorForceLogging:" >> ${ArqLogProcesso}
   echo "-----------------------------------------------------------------------------" >> ${ArqLogProcesso}
   STATUS=ERRO
   tk_severidade=2
   F_Notifica "Erro, Existem Tablespace Criadas sem a opcao FORCE_LOGGING, veja o arquivo de log (${ArqLogProcesso})" 
   exit 1
fi
#
# Valida RPO
#
P_RPO_ALERT=`expr ${TKRPO} \* ${TKRPO_ALERT} \/ 100`
P_RPO_CRITICAL=`expr ${TKRPO} \* ${TKRPO_CRITICAL} \/ 100`

for i in `cat ${ArqLogTemp} |grep "^Recovery_Point_Objetive:" 2>> ${ArqLogProcesso} ` 
do
  P_thread=`echo $i |cut -f2 -d:`
  P_seq=`echo $i |cut -f3 -d:`
  P_RPO=`echo $i |cut -f4 -d:`

  if [ "${P_RPO}" -gt "${P_RPO_ALERT}" -a "${P_RPO}" -lt "${P_RPO_CRITICAL}" ]
  then
     # ALERTA EM AMARELO COM BAIXA PRIORIDADE
     STATUS=ERRO
     if [ "${tk_severidade}" -lt "1" ]
     then
        tk_severidade=1
     fi
     F_Display  "Atencao, RPO em nivel de alerta (> ${TKRPO_ALERT}%), Valor acordado (${TKRPO}mi). Valor Monitorado para Thread(${P_thread}) e Sequence (${P_seq}) eh (${P_RPO}mi)."
  fi 

  if [ "${P_RPO}" -gt "${P_RPO_CRITICAL}" -a "${P_RPO}" -lt "${TKRPO}" ]
  then
     # ALERTA EM VERMELHO COM ALTA PRIORIDADE
     STATUS=ERRO
     if [ "${tk_severidade}" -lt "2" ]
     then
        tk_severidade=2
     fi
     F_Display  "Atencao, RPO em nivel Critico (> ${TKRPO_CRITICAL}%), Valor acordado (${TKRPO}mi). Valor Monitorado para Thread(${P_thread}) e Sequence (${P_seq}) eh (${P_RPO}mi)."
  fi 

  if [ "${P_RPO}" -gt "${TKRPO}" ]
  then
     # SLA FURADO ERRO O Acordo com o Cliente nao foi cumprido
     STATUS=ERRO
     if [ "${tk_severidade}" -lt "3" ]
     then
        tk_severidade=3
     fi
     F_Display  "Erro, RPO Nao Foi Atendido, Valor acordado (${TKRPO}mi). Valor Monitorado para Thread(${P_thread}) e Sequence (${P_seq}) eh (${P_RPO}mi)."
  fi 
done

#########################################
# Notifica a Problema ou Alerta com RPO #
#########################################
if [ "$STATUS" = "ERRO" ] && [ "${tk_severidade}" = "3" ]
then
   tk_severidade=2
   F_Display     "Erro, RPO Nao Foi Atendido!!!"
   F_Notifica    "Erro, RPO Nao Foi Atendido!!!"
   exit 1
fi 
if [ "$STATUS" = "ERRO" ] && [ "${tk_severidade}" = "2" ]
then
   F_Notifica "Atencao, RPO em nivel Critico (> ${TKRPO_CRITICAL}%), Valor acordado (${TKRPO}mi)!!!"
fi 
if [ "$STATUS" = "ERRO" ] && [ "${tk_severidade}" = "1" ]
then
   F_Notifica "Atencao, RPO em nivel de alerta (> ${TKRPO_ALERT}%), Valor acordado (${TKRPO}mi)!!!"
fi 
if [ "$STATUS" = "OK" ]
then
    F_Display "Sucesso, RPO foi atendido!"
fi 


#
# Valida RTO
#
P_RTO=`cat ${ArqLogTemp} |grep "^Recovery_Time_Objetive:" |cut -f2 -d: 2>> ${ArqLogProcesso}` 
P_RTO_ALERT=`expr ${TKRTO} \* ${TKRTO_ALERT} \/ 100`
P_RTO_CRITICAL=`expr ${TKRTO} \* ${TKRTO_CRITICAL} \/ 100`

  if [ "${P_RTO}" -lt "${P_RTO_ALERT}" ]
  then
      F_Display "Sucesso, RTO foi atendido em (${P_RTO}) minutos."
  fi

  if [ "${P_RTO}" -gt "${P_RTO_ALERT}" -a "${P_RTO}" -lt "${P_RTO_CRITICAL}" ]
  then
     # ALERTA EM AMARELO COM BAIXA PRIORIDADE
     STATUS=ERRO
     tk_severidade=1
     F_Display  "Atencao, RTO em nivel de alerta (> ${TKRTO_ALERT}%), Valor acordado (${TKRTO}mi). Valor Monitorado (${P_RTO}mi)."
     F_Notifica "Atencao, RTO em nivel de alerta (> ${TKRTO_ALERT}%), Valor acordado (${TKRTO}mi). Valor Monitorado (${P_RTO}mi)."
  fi 

  if [ "${P_RTO}" -gt "${P_RTO_CRITICAL}" -a "${P_RTO}" -lt "${TKRTO}" ]
  then
     # ALERTA EM VERMELHO COM ALTA PRIORIDADE
     STATUS=ERRO
     tk_severidade=2
     F_Display  "Atencao, RTO em nivel Critico (> ${TKRTO_CRITICAL}%), Valor acordado (${TKRTO}mi). Valor Monitorado (${P_RTO}mi)."
     F_Notifica "Atencao, RTO em nivel Critico (> ${TKRTO_CRITICAL}%), Valor acordado (${TKRTO}mi). Valor Monitorado (${P_RTO}mi)."
  fi 

  if [ "${P_RTO}" -gt "${TKRTO}" ]
  then
     # SLA FURADO ERRO O Acordo com o Cliente nao foi cumprido
     STATUS=ERRO
     tk_severidade=2
     F_Display  "Erro, RTO Nao Foi Atendido, Valor acordado (${TKRTO}mi). Valor Monitorado (${P_RTO}mi)."
     F_Notifica "Erro, RTO Nao Foi Atentido, Valor acordado (${TKRTO}mi). Valor Monitorado (${P_RTO}mi)."
  fi

#
# Valida Time da Ultima Atualizacao
#
P_TWU=`cat ${ArqLogTemp} |grep "^TimeSemUpdate:" |cut -f2 -d: 2>> ${ArqLogProcesso}`
  
if [ "${P_TWU}" -gt "${TKTWU}" ]
then
     # Tempo maximo sem update
     STATUS=ERRO
     tk_severidade=2
     F_Display  "Erro, TWU Nao Foi Atendido, Servidor Standby com (${P_TWU}mi) sem Atualizacao. Valor acordado (${TKTWU}mi)."
     F_Notifica  "Erro, TWU Nao Foi Atendido, Servidor Standby com (${P_TWU}mi) sem Atualizacao. Valor acordado (${TKTWU}mi)."
else
     F_Display  "Sucesso, TWU foi atendido em (${P_TWU}) minutos."
fi

}
F_Envia_Resumo()
{
w_flag_resumo=0
hora=`date '+%H'`
if [ "${TkNotifica}" != "MTMON" -a "${TkNotifica}" != "FAROL" ]
then
    if [ -f "${ArqLogResumo}" ]
    then
       # Se o arquivo de Resumo Jah existe, indica que o resumo foi enviado uma vez no dia. 
       echo "" >/dev/null 
    else
       STATUS=OK
       if [ -f "${ArqLogResumoAtu}" ]
       then
           F_Display "Enviando Resumo de Atualização do Banco Standby para o email ${email_destino_log}" 
           cat ${ArqLogResumoAtu} > ${ArqLogResumo} 1>>${ArqLogProcesso} 2>>${ArqLogProcesso}
           w_flag_resumo=1
           F_Notifica "Resumo de Atualização do Banco Standby" 
           w_flag_resumo=0
       fi
    fi
fi
}
########################
# Controle de Processo #
########################
# Varivaies Locais
nm_programa=TkCheckSLA

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

#######################
# Chamada das Funcoes #
#######################
# Inicializa variaveis de ambiente
F_Inicio $1

# Valida Configuracao do Ambiente
F_Valida_Ambiente

# Envia Resumo de Atualização do Standby
# Uma vez ao dia para Clientes sem Monitoramento
F_Envia_Resumo

# Transfere arq. de Controle SLA para os Sites Primarios
# Arquivo---> RPO
ArqExTableSLA="${DirSLA}/RPO_${ORACLE_SID}_`date '+%Y%m%d'`.txt"
NmArqExTable=RPO_${ORACLE_SID}.txt
F_Transfere_Arq_SLA

# Transfere arq. de Controle SLA para os Sites Primarios
# Arquivo---> RPO
ArqExTableSLA="${DirSLA}/RTO_${ORACLE_SID}_`date '+%Y%m%d'`.txt"
NmArqExTable=RTO_${ORACLE_SID}.txt
F_Transfere_Arq_SLA

# Transfere arq. de Controle SLA para os Sites Primarios
# Arquivo---> TWU
ArqExTableSLA="${DirSLA}/TWU_${ORACLE_SID}_`date '+%Y%m%d'`.txt"
NmArqExTable=TWU_${ORACLE_SID}.txt
F_Transfere_Arq_SLA

# Relatorio de Atualizacao
F_Controla_SLA

# Atualiza Controle de Execucao
F_Controla_Execucao

F_Display "Fim da Conferencia com Sucesso!!!"
