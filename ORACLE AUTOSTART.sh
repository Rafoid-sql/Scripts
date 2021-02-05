######################################################################################################
#! /bin/sh -x
# chkconfig: 2345 80 05
# Description: start and stop Oracle Database on Oracle Linux 5, 6 and 7.
# In /etc/oratab, change the autostart field from N to Y for any databases that you want autostarted.
# Create this file as "/etc/init.d/dbora" and execute:
#		chmod 750 /etc/init.d/dbora
# Set service autostart: 
#		Oracle Linux 5 and 6:
#				chkconfig add dbora
#				chkconfig dbora on
#		Oracle Linux 7:
#				systemctl enable dbora
# Start, stop or restart database:
#		service dbora start
#		service dbora stop
#		service dbora restart
# Change the value of ORACLE_HOME to specify the correct Oracle home directory.
# Change the value of ORACLE to the login name of the oracle owner.
######################################################################################################

#. /etc/ambiente_dbprod.sh

ORACLE_HOME=/home/app/oracle/product/11.2.0/dbhome_1
ORACLE=oracle

PATH=${PATH}:${ORACLE_HOME}/bin
HOST=`hostname`
PLATFORM=`uname`
export ORACLE_HOME PATH
case $1 in
'start')
        echo -n $"Starting Oracle: "
		su ${ORACLE} -c "${ORACLE_HOME}/bin/lsnrctl start" &
        su ${ORACLE} -c "${ORACLE_HOME}/bin/dbstart ${ORACLE_HOME}" &
        ;;
'stop')
        echo -n $"Shutting down Oracle: "
		su ${ORACLE} -c "${ORACLE_HOME}/bin/lsnrctl stop" &
        su ${ORACLE} -c "${ORACLE_HOME}/bin/dbshut ${ORACLE_HOME}" &
        ;;
'restart')
        echo -n $"Shutting down Oracle: "
		su ${ORACLE} -c "${ORACLE_HOME}/bin/lsnrctl reload" &
        su ${ORACLE} -c "${ORACLE_HOME}/bin/dbshut ${ORACLE_HOME}" &
        sleep 5
        echo -n $"Starting Oracle: "
        su ${ORACLE} -c "${ORACLE_HOME}/bin/dbstart ${ORACLE_HOME}" &
        ;;
*)
        echo "usage: $0 {start|stop|restart}"
        exit
        ;;
esac
exit



(executar tudo com o usuario ROOT)

## Aplicar permissão:
chmod 750 /etc/init.d/dbora


## Cadastrar o dbora no init:
- Oracle Linux 5 e 6:
chkconfig --add dbora
chkconfig dbora on

- Oracle Linux 7:
systemctl enable dbora


Iniciar / Parar o banco de dados:
service dbora start
service dbora stop

Iniciar PDB no Oracle 12c:

SQLPLUS / AS SYSDBA

CREATE OR REPLACE TRIGGER SYS.AFTER_STARTUP AFTER STARTUP ON DATABASE
BEGIN
   EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ALL OPEN';
END AFTER_STARTUP;
/