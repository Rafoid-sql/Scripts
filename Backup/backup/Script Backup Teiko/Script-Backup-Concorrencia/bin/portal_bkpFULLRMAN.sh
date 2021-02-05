#!/bin/sh 
# Backup RMAN FULL Online Compressed

#************ Variaveis de Ambiente *****************
export ORACLE_SID=portal
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_UNQNAME=portal
export ORACLE_HOSTNAME=dboraprod
export PATH=/u01/app/oracle/product/11.2.0/bin:/usr/sbin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/oracle/bin
export PATH=$ORACLE_HOME:/usr/sbin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin

#************** Criando Diretorio de Backup ********
DATA=`date '+%d-%m-%Y'`
mkdir -p /u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/

#************** Executando Backup RMAN *************
$ORACLE_HOME/bin/rman<<EOO
connect target /
SPOOL log to '/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/LOG_RMAN_portal.log' ;
run {
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/controlfile.ctl%F';
allocate channel d1 type disk format '/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/bkp_%U';
backup as compressed backupset format '/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/bkupfull_%d_%T_%U.bkp' database;
backup as compressed backupset format '/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/archlog_%d_%u.arc' archivelog all;
backup spfile format '/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/spfile_%d_%s_%T.ora'; 
SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
release channel d1;
}
SPOOL log off;
exit
EOO

#************ Envia e-mail com log ******************
DE="dba@s1ti.com.br"
USUARIO="dba@s1ti.com.br"
SENHA='!@#DbaS1ti'
SMTP="email-ssl.com.br"
PARA="silviodauricio@gmail.com"
ASSUNTO="AEBEL_LOG_RMAN_portal"
ANEXO="/u03/portal/backupRMAN/backup_FULL_RMAN_$DATA/LOG_RMAN_portal.log"
/home/oracle/scripts/bin/sendEmail/sendEmail -f $DE -t $PARA -u $ASSUNTO -a $ANEXO -s $SMTP:587 -xu $USUARIO -xp $SENHA  -m $ASSUNTO

