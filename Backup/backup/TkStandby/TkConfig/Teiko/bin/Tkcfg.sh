# Programa   : Tkcfg.sh
# Funcao     : Carregar as Variaveis de Ambiente com base no Archivo de Configuracao
#
# Autor      : Djalma Luciano Zendron - Teiko
# Data.........: 10/07/2007
# Sintaxe......: sh Tkcfg.sh <TEIKO> <Chave>
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
F_CargaConfig(){
###################################
# Leitura do Arquivo de Parametro #
###################################
ArqWork=/usr/tmp/${nm_programa}.$$
cat > /tmp/${nm_programa}.$$.awk <<EndOfAWK
/^ *\#/ { next }
/^ *$/ { next }
/^\[${P_Chave}\]/ { Imprime=1; next }
/^\[DEFAULT\]/ { Imprime=1; next }
/^\[/ { Imprime=0; next }
Imprime == 1
EndOfAWK

awk -f /tmp/${nm_programa}.$$.awk ${Tk_ArqConfig} > ${ArqWork}

########################################
# Atribui as Variaveis para o Ambiente #
########################################
cat ${ArqWork} |sed -e "s/=/=\"/"|sed -e "s/$/\"/" > /tmp/${nm_programa}.$$.awk
. /tmp/${nm_programa}.$$.awk
}

#####################################
# Salva o Nome do Programa Chamador #
#####################################
P_nm_programa=${nm_programa}

##################
# Nome do Script #
##################
nm_programa=Tkcfg
export nm_programa

#################################
# Controle de Execucao do Shell #
#################################

if [ "$#" -lt "2" ]
then
    echo "${nm_programa}.sh: Sintax Error!!!" 
    echo "Use.............: Tkcfg.sh <Produto> <Chave>" 
    exit 1
fi
P_Produto=`echo $1 |tr "a-z" "A-Z"`
P_Chave=`echo $2 |tr "a-z" "A-Z"`

#######################################################
# Carrega Variaveis de Localizacao dos Produtos Teiko #
#######################################################
if [ "${P_Produto}" = "TEIKO" ]
then
    Tk_ArqConfig=/etc/Teiko.conf
    if [ ! -f "${Tk_ArqConfig}" ]
    then
        echo "Arquivo de Configuracao de Variaveis Nao foi Encontrado"
        echo "(${ArqConfig})" 
        exit 1
   fi
fi
#################################
# Funcao de Carga das Variaveis #
#################################
F_CargaConfig

# Remove Archivos Temporarios
rm -f /tmp/${nm_programa}.$$.awk
rm -f /usr/tmp/${nm_programa}.$$

# Recupera o Nome do Programa Chamador
nm_programa=${P_nm_programa}
export nm_programa
