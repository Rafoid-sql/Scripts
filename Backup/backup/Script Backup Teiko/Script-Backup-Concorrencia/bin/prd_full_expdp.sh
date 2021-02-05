#!/bin/sh 
#Script to do full database export ....

export ORACLE_SID=prd
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_UNQNAME=prd
export ORACLE_HOSTNAME=dboraprod
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export DATEFORMAT=`date +'%d-%m-%Y'`
export EXPFOLDER=/u03/prd/backupEXPDP/`date +'%d-%m-%Y'`
mkdir $EXPFOLDER
export VDATEDELETE=`date +'%d-%m-%Y' -d "4 days ago"`
export PATH=/u01/app/oracle/product/11.2.0/db_1/bin:/usr/sbin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/oracle/bin

## MANTEM SEMPRE OS ULTIMOS 4 BACKUPS NO REPOSITORIO LOCAL #########
rm -rf /u03/prd/backupEXPDP/$VDATEDELETE

expdp \"/ as sysdba\" directory=PRD_EXPORT_DUMP_DIR dumpfile=fullexpdp_`echo $ORACLE_SID`_%U_`echo $DATEFORMAT`.expdp logfile=log_`echo $ORACLE_SID`_`echo $DATEFORMAT`.log full=Y 
#expdp amm/amm@prd directory=PRD_EXPORT_DUMP_DIR dumpfile=fullexpdp_`echo $ORACLE_SID`_%U_`echo $DATEFORMAT`.expdp logfile=log_`echo $ORACLE_SID`_`echo $DATEFORMAT`.log

find /u03/prd/backupEXPDP/fullexpdp*.expdp -exec /bin/gzip '{}' \;

find /u03/prd/backupEXPDP/fullexpdp*.expdp.gz -exec mv '{}' $EXPFOLDER \;
find /u03/prd/backupEXPDP/log*.log -exec mv '{}' $EXPFOLDER  \;

#********* ENVIA LOG POR E-MAIL *****
DE="dba@s1ti.com.br"
USUARIO="dba@s1ti.com.br"
SENHA='!@#DbaS1ti'
SMTP="email-ssl.com.br"
PARA="silviodauricio@gmail.com"
ASSUNTO="AEBEL_LOG_DATAPUMP_prd"
ANEXO="$EXPFOLDER/log_`echo $ORACLE_SID`_`echo $DATEFORMAT`.log"
/home/oracle/scripts/bin/sendEmail/sendEmail  -f $DE -t $PARA -u $ASSUNTO -a $ANEXO -s $SMTP:587 -xu $USUARIO -xp $SENHA  -m $ASSUNTO






