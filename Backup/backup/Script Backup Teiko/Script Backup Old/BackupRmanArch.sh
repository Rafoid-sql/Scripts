[oracle@shosbd ~]$ cat /orabackup/dbprod/rman/script/BackupRmanArch.sh
#!/bin/bash

. /etc/ambiente_ora.sh

export BASE_DIR=/orabackup/dbprod/rman
export LOCAL_DIR=/bkpremoto
export REMOTE_DIR=//shoshbd/backup/dbprod/rman
export EXTERNO_DIR=/hdexterno
export BACKUP_DIR=${BASE_DIR}/file
export LOGFILE=${BASE_DIR}/log/RmanArchBackup_`date '+%Y%m%d'`.log
export RETENCAO=6
export STATUS=0
export STATUS2=0

#
## envia e-mail com erro
#
envia_email_erro() {
cat $LOGFILE | mail -s "BKP_ERRO : Erro na rotina de backup Archives. Ver conteudo do e-mail." sas@unimednp.com.br
}

#
## envia e-mail comsucesso
#
envia_email_sucesso() {
cat $LOGFILE | mail -s "BKP_SUCESSO : Sucesso na rotina de backup Archives." sas@unimednp.com.br
}



rman <<!EOF > $LOGFILE 2>&1
CONNECT TARGET /;
RUN {
 CONFIGURE RETENTION POLICY TO REDUNDANCY 1;
 CONFIGURE BACKUP OPTIMIZATION OFF; # default
 CONFIGURE DEFAULT DEVICE TYPE TO DISK; # default
 CONFIGURE CONTROLFILE AUTOBACKUP ON;
 CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/orabackup/dbprod/rman/file/controlfile_%F';
 CONFIGURE DEVICE TYPE DISK PARALLELISM 1 BACKUP TYPE TO BACKUPSET; # default
 CONFIGURE DATAFILE BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
 CONFIGURE ARCHIVELOG BACKUP COPIES FOR DEVICE TYPE DISK TO 1; # default
 CONFIGURE MAXSETSIZE TO UNLIMITED; # default
 CONFIGURE ENCRYPTION FOR DATABASE OFF; # default
 CONFIGURE ENCRYPTION ALGORITHM 'AES128'; # default
 CONFIGURE COMPRESSION ALGORITHM 'BASIC' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE ; # default
 CONFIGURE ARCHIVELOG DELETION POLICY TO NONE; # default
 CONFIGURE SNAPSHOT CONTROLFILE NAME TO '/orabackup/dbprod/rman/file/snapcf_dbprod.f'; # default
 CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT   '/orabackup/dbprod/rman/file/archive_%d_%T_s%s_p%p';
 SQL 'alter system archive log current';
 BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL NOT BACKED UP DELETE ALL INPUT;
 DELETE NOPROMPT OBSOLETE;
}
exit;
!EOF


STATUS=$?

#if [ ${STATUS} == 0 ]; then
#   sudo  /bin/umount -l ${LOCAL_DIR} > /dev/null
#   sudo  /bin/umount -l ${EXTERNO_DIR} > /dev/null

#   echo "Montando filesystem do backup remoto..." >> $LOGFILE 2>&1
#   sudo  /sbin/mount.cifs ${REMOTE_DIR} ${LOCAL_DIR} -o username=oracle,password=oracle >> $LOGFILE 2>&1
#   STATUS=$?

#   echo "Montando filesystem do backup HD externo..." >> $LOGFILE 2>&1
#   sudo  /bin/mount ${EXTERNO_DIR} >> $LOGFILE 2>&1
#   STATUS2=$?

#   if [ ${STATUS} == 0 ] && [ ${STATUS2} == 0 ]; then
      echo "Copiando arquivos do backup de archives.." >> $LOGFILE 2>&1
      sudo  find ${LOCAL_DIR}/file/* -mtime +${RETENCAO} -exec rm -f {} \; >> $LOGFILE 2>&1
      sudo  rsync -v --ignore-existing ${BASE_DIR}/file/* ${LOCAL_DIR}/file
      STATUS=$?

      echo "Copiando arquivos do backup de archives HD.." >> $LOGFILE 2>&1
      sudo  find ${EXTERNO_DIR}/dbprod/rman/file/* -mtime +${RETENCAO} -exec rm -f {} \; >> $LOGFILE 2>&1
      sudo  rsync -v --ignore-existing ${BASE_DIR}/file/* ${EXTERNO_DIR}/dbprod/rman/file
      STATUS2=$?

#      if [ ${STATUS} == 0 ] && [ ${STATUS2} == 0 ]; then
#         echo "Desmontando filesystem do backup remoto..." >> $LOGFILE 2>&1
#         sudo  /bin/umount -l ${LOCAL_DIR} >> $LOGFILE 2>&1
#         STATUS=$?

#         echo "Desmontando filesystem do backup HD Externo..." >> $LOGFILE 2>&1
#         sudo  /bin/umount -l ${EXTERNO_DIR} >> $LOGFILE 2>&1
#         STATUS2=$?
#      fi
#   fi
#fi


if [ ${STATUS} == 0 ] && [ ${STATUS2} == 0 ]; then
   envia_email_sucesso
else
   envia_email_erro
fi

####################
# LIMPEZA DOS LOGS #
####################
find ${BASE_DIR}/log/RmanArchBackup* -mtime +30 -print -exec rm -f {} \; > /dev/null 2>&1

