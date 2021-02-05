#
# Procedimento de Instalacao e Atualizacao do TkStandby.
##################################################################
# 1) Etapa - Em caso de Atualizacao, salvar o arquivo TkStandby.conf .
# 
# 2) Etapa - Em caso de Atualizacao, para identificar novos parametros do TkStandby.conf, execute os seguintes comandos:
# 
# 2.1) Criar uma area temporaria para descompactar o pacote
# 
# $ cd $ORACLE_BASE
# $ mkdir temp
# $ cd temp
# $ tar -xvzf Teiko_TkStandby_v3.20080821.tar.gz
# 
# 2.2) Identificando as novas variaveis.
# 
#   $ cd $ORACLE_BASE/temp/Teiko/TkStandby/script
#   $ cp TkStandby.conf /$ORACLE_BASE/temp/TkStandby.novo
#   $ cd $ORACLE_BASE/Teiko/TkStandby/script/
#   $ cp TkStandby.conf /$ORACLE_BASE/temp/TkStandby.velho
# 
#   $ cd /$ORACLE_BASE/temp/
#   $ cat TkStandby.velho |grep -v "#" |cut -f1 -d"=" > parametros.velho
#   $ cat TkStandby.novo  |grep -v "#" |cut -f1 -d"=" > parametros.novo
#   $ diff parametros.velhos parametros.novo > ajustes.txt
# 
#   Nota: Neste ponto voce tera a lista de parametros incluidos ou excluidos para que seja feito o ajuste no TkStandby.conf
#-------------------------------------------------------------------------------------------------------------------------------- 
# 3) Procedimento para Instalacao
#  
# 3.1) Verificar se o Teiko_TkConfig_v1.20080821.tar.gz foi instalado e fazer os ajustes no Teiko.conf
#    
#    A instalacao cria o diretorio $ORACLE_BASE/Teiko/bin
#    e tambem cria os links no /etc para os arquivivos Teiko.conf e Tkcfg.sh
#  
# 3.2) Instalando o TkStandby.
#   $ cd $ORACLE_BASE
#   $ tar -xvzf Teiko_TkStandby_v3.20080821.tar.gz
# 
# 4) Ajuste do TkStandby.conf de acordo com as necessidade identificadas no item 2.2.
# 
# 5) Remover o diretorio temporario criado no item 2.1.
# 
#   $ cd $ORACLE_BASE
#   $ rm -rf temp
# 
# 5) Executar o TkTesteNotifica.sh - Para Validar se o processo de Notificacao escolhido esta funcionando corretamente.
#   $ sh TkTesteNotifica.sh <ORACLE_SID> 
#
# IMPORTANTE: Após o teste faça a conferência do recebimento da notificação.
# 6) Incluir no crontab do usuario oracle a chamada para os seguintes scripts.
# 
#    $ crontab -e
# 
# Exemplo:
# # Efetuado ajuste dos minutos de execucao manual para nao gerar conflito com o backup de archives
# 2,7,12,17,22,27,32,37,42,47,52,57 * * * * sh /orastd01/app/oracle/Teiko/TkStandby/script/TkCopiaArchive.sh DBPRD
# 
# # Atualizacao do banco standby com base na producao cada 1 horas
# 08 * * * * sh /orastd01/app/oracle/Teiko/TkStandby/script/TkAtualizaStandby.sh DBPRD
# 
# # Conferencia dos indicadores de SLA a cada quinze minutos
# */2 * * * * sh /orastd01/app/oracle/Teiko/TkStandby/script/TkCheckSLA.sh DBPRD
# 
# # Limpeza do ambiente standby uma vez ao dia
# 15 1 * * * sh /orastd01/app/oracle/Teiko/TkStandby/script/TkLimpaStandby.sh DBPRD
# 
#   
# ----------------------------------------------FIM--------------------------------------------------------------

