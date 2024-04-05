## INSTANCIAS ##

# Prompt Settings
export PS1='[\u@\h:\[\e[01;31m$ORACLE_SID\e[m\] $PWD]\$ '

# History Settings
export HISTTIMEFORMAT="%d/%m/%y %T "
export HISTFILESIZE=1500
export HISTCONTROL=ignorespace
export HISTCONTROL=ignoredups

# Oracle Settings
export ORACLE_SID=viasoft
export ORACLE_HOSTNAME=dbora
export ORACLE_UNQNAME=viasoft
export JAVA_HOME=/usr/local/java
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export AGENT_HOME=/u01/oraagt/agent13c/agent_13.4.0.0.0
export ORACLE_TERM=xterm
export TNS_ADMIN=$ORACLE_HOME/network/admin
export NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"
export ORA_NLS11=$ORACLE_HOME/nls/data
export PATH=.:${JAVA_HOME}/bin:${PATH}:$HOME/.local/bin:$HOME/bin:$ORACLE_HOME/bin:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin:/u01/app/common/oracle/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/oracm/lib:/lib:/usr/lib:/usr/local/lib:$ORACLE_HOME
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib
export THREADS_FLAG=native
export TMP=/tmp
export TMPDIR=$TMP

umask 022

# Aliases
alias orbase='cd $ORACLE_BASE'
alias orhome='cd $ORACLE_HOME'
alias oragent='cd $AGENT_HOME'
alias ortns='cd $ORACLE_HOME/network/admin'
alias orenvo='env | grep ORACLE'
alias oralert='find $ORACLE_BASE -name alert_$ORACLE_SID.log'
alias oralertout='find / -type f -name alert_$ORACLE_SID.log -print0 2>&1 | grep -v "Permission denied"'

alias or<sid>='export ORACLE_SID=<sid>'












## ESQUEMA DE CORES ##

# SSH
	#PRD: vermelho 100
	#STB: verde 100
	#TST: azul 100
	#WRK: vermelho/verde/azul 100

# RDP
	#vermelho/verde 255