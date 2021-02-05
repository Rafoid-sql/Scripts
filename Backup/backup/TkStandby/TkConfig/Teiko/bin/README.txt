# 
# Procedimento para Instalacao do TkConfig
#
---------------------------------------INICIO----------------------------------------------------

1) Etapa - Importante: Salvar o arquivo de configuracao (Teiko.conf) caso exista.

2) Etapa - Instalando o pacote abaixo do $ORACLE_BASE e conectando com o usuario oracle.

$ cd $ORACLE_BASE
$  tar -xvzf Teiko_TkConfig_v1.20080821.tar.gz
Teiko/bin/
Teiko/bin/Teiko.conf
Teiko/bin/Tkcfg.sh
Teiko/bin/README.txt


3) Etapa - Criando links do diretorio /etc.

$ cd /etc
ln -s $ORACLE_BASE/Teiko/bin/Teiko.conf  Teiko.conf

$ cd /usr/local/bin
ln -s $ORACLE_BASE/Teiko/bin/Tkcfg.sh  Tkcfg.sh


4) Etapa - Configura o Arquivo Teiko.conf.

Edite o arquivo a faca os ajustes necessarios das chaves e variaveis existentes.

Exemplo:

[TKCLONESCHEMA]  <<<- Chave para a instalacao do TKClone
      # Diretorio dos Scripts da Aplicacao TkCloneSchema
      DirScript=/u01/app/oracle/Teiko/TkClone/script        <<<<- Variavel para o diretorio onde os scripts do TkClone foram instalados.
      Tk_ArqConfig=/u01/app/oracle/Teiko/TkClone/script/TkClone.conf  <<<<- Variavel para o arquivo de configuracao do TkClone.


-------------------------------------------FIM-------------------------------------------------------------------------------------


