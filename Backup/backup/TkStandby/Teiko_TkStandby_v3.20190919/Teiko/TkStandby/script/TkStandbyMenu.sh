# Programa     : TkClone.sh
# Funcao       : 
#              
#
# Autor        : Djalma Luciano Zendron - Teiko
# Data.........: 10/07/2007
# Sintaxe......: sh TkClone
###############################################################################
#------------------------------------------------------------------------------
# Alterado por : Djalma Luciano Zendron
#  - (Data)....:
#  -...........:  
#------------------------------------------------------------------------------
# Alterado por :  
#  - (Data)....:
#  -...........:  
###############################################################################
Versao=v2.1.3
TELA() {
   #trap "" 1 2 3 15
   tput clear
   echo "--------------------------------------------------------------------------------"
   echo "${cliente}                    TEIKO STANDBY DATABASE                     "
   tput cup 1 59; echo "${nm_programa}(${Versao})"
   echo "Tela de Administracao do Standby Database                     `date '+%d/%m/%y  %H:%M:%S'`"
   echo "--------------------------------------------------------------------------------"
   tput cup 20 01
   echo "-------------------------------------------------------------------------------"
}

LIMPA_TELA(){
linha=$1
while true 
do 
  linha=`expr $linha + 1`
  tput cup $linha 1;echo "                                                                               "
  if [ $linha = $2 ]
  then 
    break
  fi
done 
}

SELECAO_DE_DATABASE ()
{
tput cup 05
echo "

                       Selecione um Banco para Trabalhar
                       ---------------------------------
"
tput cup 21 01; echo "Aviso: Para Finalizar Digite <Enter>                                           "
linha=10
conta=0
unset ORACLE_SID
for i in ` echo $ListaDBNAME_STANDBY`
do
  conta=`expr ${conta} + 1 `
  export ORACLE_SID=${i}
done

if [ ${conta}  -gt 1 ] 
then
   for i in  `echo $ListaDBNAME_STANDBY`
   do
     echo ":$i:" >> ${ArqTemp}
     tput cup ${linha} 15 ; echo "Banco em Standby...: ${i}"
     linha=`expr ${linha} + 1 `
   done
     linha=`expr ${linha} + 1 `
     while true
     do
       tput cup ${linha} 15; echo "-> Enter com o Nome do Banco Standby...:                      "
       tput cup ${linha} 56;  read _opcao
       if [ "${_opcao}" = "" ]
       then
          exit 1
       fi
       cat ${ArqTemp} | grep ":${_opcao}:"  >> /dev/null
       if [ "$?" = "0" ]
       then
           export ORACLE_SID=${_opcao}
           break
       else
          tput cup `expr ${linha} + 2` 15; echo "Opcao Invalida, Digite Enter"
          read a
          tput cup `expr ${linha} + 2` 15; echo "                               "
       fi
      
     done
fi
}

OPCOES ()
{
while true
do
TELA
LIMPA_TELA 04 19
tput cup 05 01
echo "
1) Standby...: Ativa Banco em modo READ ONLY
2) Standby...: Shutdown no Banco Standby
3) Standby...: Atualiza Banco 
4) Standby...: Copia Archive da Producao para o Servido Standby
5) Standby...: Ativa Banco Standby como Primario
6) Standby...: Verificar de Ultimo Log de Copia de Archive
7) Standby...: Verificar de Ultimo Log de Atualizacao do Standby
8) Linux.....: Verificar de area em disco

f) Finaliza menu
"
while true
do
  tput cup 21 0; echo "Opcao:                                       "
  tput cup 21 7; read opcao
  case $opcao in
     f|F) exit
        ;;
     1) ${DirScript}/TkAtivaStandbyReadOnly.sh ${ORACLE_SID}
        break
        ;;

     2) ${DirScript}/TkShutdownStandby.sh ${ORACLE_SID}
        break
        ;;

     3) clear
        echo $ORACLE_SID
        echo "Atencao:
Este procedimento irah atualizar o banco standby ateh o ultimo archive disponivel no
servidor standby em producao.
-------------------------------A T E N C A O ----------------------------------------
Sempre Execute uma Copia dos Archive de Producao para o Standby com a Finalidade
de Manter o Standby o Maximo possivel Atualizado ANTES DE EXECUTAR ESTE PROCEDIMENTO!!!

Para Ter Certeza do Sucesso da Copia Confira os LOGS!!!
-------------------------------A T E N C A O ----------------------------------------

Confirme execucao (s)"
read conf
        if [ "$conf" = "s" ]
        then
           # Atualiza o Banco com todos os archives disponiveis sem DELAY em relacao a producao
           TKDTU_MENU=0 ; export TKDTU_MENU
           ${DirScript}/TkAtualizaStandby.sh ${ORACLE_SID}
        else
           echo "Opcao invalida"
        fi
        echo "Tecle <Enter> "
        read a
        break
        ;;

     5) clear
   # crontab -l |grep -v "^#" |grep TkAtualiza
echo "Atencao:
Este procedimento irah ATIVAR o banco STANDBY como PRIMARIO !!!

------------------------------------------A T E N C A O ----------------------------------------
Veja alguns Pontos Importantes ANTES de ATIVAR o STANDBY:

1) Parar o processo de atualizacao que esta agendado no crontab. Programa TkAtualiza.sh
2) Executar o processo de Copia Dos Archives possiveis foram copiados do servidor Primario.
3) Executar o procedimento de Atualizacao, para atualizar o banco Standby Antes de Ativar.

Apos executado as tres etapas acima voce jah pode ativar o banco STANDBY como Servidor Primario.

IMPORTANTE: 
     1) Para Ter Certeza do Sucesso da Copia e da Atualizacao, Confira os LOGS, ou solicite
        ajuda de um DBA da Teiko!!!
     2) Apos estes procedimento, o banco standby deverah ser reconstruido!!!

------------------------------------------A T E N C A O ----------------------------------------


Confirme execucao (Sim)"
read conf
        if [ "$conf" = "Sim" ]
        then
           crontab -l |grep -v "^#" | grep TkAtualiza
           if [ "$?" = "0" ]
           then
              echo "
------------------------------------------A T E N C A O ----------------------------------------
 O TkAtualiza.sh ainda esta agendado no crontab. Comente ou remova esta entrada antes de  Ativar
 o banco Standby.

 Digite Enter para Voltar ao Menu
------------------------------------------A T E N C A O ----------------------------------------
"
              read a
              break
              clear
           else
              ${DirScript}/TkAtivaStandbyReadWrite.sh  ${ORACLE_SID}
           fi
        else
           echo "Opcao invalida"
        fi
        echo "Ativando o Listener..."
        $ORACLE_HOME/bin/lsnrctl start
        echo "Tecle <Enter> "
        read a
        break
        ;;
     6) clear
        export CPARCH=`ls -rt ${DirLog}/${ORACLE_SID}*TkCopiaArchive* | tail -n1`
        more ${CPARCH}
        echo "Tecle <Enter> para finalizar"
        read a
        break
        ;;

     7) clear
        export STDBLOG=`ls -rt ${DirLog}/*TkAtualizaStandby* | tail -n1`
        more ${STDBLOG}
        echo "Tecle <Enter> para finalizar"
        read a
        break
        ;;

     8) clear
        echo "Servidor: `hostname`"
        echo "Data: `date`"
        df -k
        echo "Tecle <Enter> para finalizar"
        read a
        break
        ;;
     *) echo >>/dev/null
        ;;
  esac
done
done
}

#######################
# Inicio da Execucao  #
#######################
nm_programa=TkStandbyMenu
ArqTemp=/tmp/${nm_programa}.$$
trap 'rm -f ${ArqTemp} ' 0

#
# Atribui Variaveis
#

. /usr/local/bin/Tkcfg.sh TEIKO TKSTANDBY
if [ "$?" != "0" ]
then
    echo "Erro Para Definir Variveis de Instalacao do TKSTANDBY"
    exit 1
fi

# Variaveis Globais
. /usr/local/bin/Tkcfg.sh TKSTANDBY  DEFAULT
if [ "$?" != "0" ]
then
    echo "Erro Para Definir Variaveis de Ambiente do TKSTANDBY"
    exit 1
fi
TELA
SELECAO_DE_DATABASE
OPCOES
