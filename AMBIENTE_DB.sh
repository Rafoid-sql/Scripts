## INSTANCIAS ##

# Prompt Settings
export PS1='[\u@\h:\[\e[01;31m$ORACLE_SID\e[m\] $PWD]\$ '

# History Settings
export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTFILESIZE=1500
export HISTCONTROL=ignorespace
export HISTCONTROL=ignoredups

# Oracle Settings
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=dbora
export ORACLE_UNQNAME=viasoft
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_SID=viasoft
export ORACLE_TERM=xterm
export PATH=/usr/sbin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

## INSTANCIAS APLICADAS ##

#AGROBRASIL
#AGRODANIELI
#BOMPEL
#COASUL
#HNSL
#HOSPITAL DO CORAÇÃO
#IDEALAGRO
#INDIANAAGRI
#INFASA
#MOINHO
#NINFA
#POLICLÍNICA
#RUDEGON
#SEMPREVIDA
#SPECIALITE
#TERRA CEREAIS
#VILELA

## ESQUEMA DE CORES ##

# SSH
	#PRD: vermelho 100
	#STB: verde 100
	#TST: azul 100
	#WRK: vermelho/verde/azul 100

# RDP
	#vermelho/verde 255