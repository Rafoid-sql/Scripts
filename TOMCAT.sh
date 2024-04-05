#1 - Verificar serviço do tomcat:
ps -ef|grep tomcat

#2 - Tirar print da tela e encerrar o processo:
kill -9 no processo

#3 - Localizar o diretório que o cliente passou:
/.../*.war

#4 - Localizar o diretório webapps:
cd /home/tomcat/tasy_java/webapps

#5 - remover todo conteudo da pasta work:
cd /home/tomcat/tasy_java/work
rm -rf Catalina

#6 - remover todo conteudo da pasta temp:
cd /home/tomcat/tasy_java/
rm -rf temp
mkdir temp
chown tomcat:tomcat temp/

#7 - Remover arquivos .war e diretórios antigos dentro do webapps:
cd /home/tomcat/tasy_java/webapps
rm -rf TasyReports
rm -f TasyReports.war
rm -rf WhebRepositorio
rm -f WhebRepositorio.war
rm -rf WhebServidor
rm -f WhebServidor.war

#8 - Copiar os arquivos novos para o diretório webapps:
cd /home/tomcat/tasy_java/webapps
cp -av /.../*.war /home/tomcat/tasy_java/webapps/

#9 - alterar permissões dos novos arquivos para ficarem iguais aos dos antigos
cd /home/tomcat/tasy_java/webapps
chown tomcat:tomcat *.war

#10 - Executar startup.sh dentro do diretório bin:
cd /home/tomcat/tasy_java/bin/
sh startup.sh

#11 - Verificar se o serviço do tomcat foi iniciado:
ps -ef|grep tomcat