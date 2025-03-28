#set -x
#!/bin/sh
#==========================================================================================================
#    Author: Rafael Oliveira
#   Summary: Secondary Script for the Data Transfer import and insert processes
#==========================================================================================================

#==========================================================================================================
#========= VARIABLES
#==========================================================================================================

# ORACLE
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/18.3.0/db18c
export ORACLE_SID=TTDWH004
export PATH=$PATH:$HOME/.local/bin:$HOME/bin:/u01/app/oracle/product/18.3.0/db18c/bin

# CREDENTIALS
export EMAIL=''COE_DBA@DIGICELGROUP.COM' 'TNT_IT_DWH@DIGICELGROUP.COM''
export INSTANCE=TTDWH004
export USER_PROXY=DATA_TRANSFER
export USER_PROXY_PWD='"VbUjfxnv#65Se#hr"'

# DATE
FD_CDRMSC=`date -d "1 days ago" +%Y%m%d`

# LOGFILE
touch /archive1/dumps3/scripts/logs/log_data_transfer_`date +%Y%m%d`.log
LOGFILE=/archive1/dumps3/scripts/logs/log_data_transfer_`date +%Y%m%d`.log
EMAIL_LOG=`ls /archive1/dumps3/scripts/logs/log_data_transfer_*.log | tail -1`

#==========================================================================================================
#========= EXECUTE DATAPUMP
#==========================================================================================================
EXEC_IMP()
        {
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE IMPORT STARTED." >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_cdrmsc.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_at_cdrpsl_load_bonadjt.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_at_cdrussd_loaded.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_at_lte_roam_loaded.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_at_rbgprs_loaded.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_at_rbvoice_loaded.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_st_cdrpsl_imp_bonadjt.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_st_cdrussd_import.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_st_lte_roam_import.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_st_rbgprs_import.par >> ${LOGFILE} 2>&1
                impdp 'system/"InfinityEndGame#2019!##"' parfile=/archive1/dumps3/parfile/imp_st_rbvoice_import.par >> ${LOGFILE} 2>&1
        }

#==========================================================================================================
#========= INSERT INTO CDRMSC
#==========================================================================================================
FN_INSERT()
        {
                sqlplus ${USER_PROXY}[CDRMSC]/"${USER_PROXY_PWD}" <<-EOF | tee -a ${LOGFILE}
                whenever sqlerror exit sql.sqlcode;
                show user
                insert into cdrmsc.at_cdrmsc_loaded
                select * from cdrmsc.at_cdrmsc_loaded@TTCDRMSC
                where date_call= '${FD_CDRMSC}'
                and filename not in (select filename from cdrmsc.at_cdrmsc_loaded where date_call= '${FD_CDRMSC}');
                commit;
                quit
                EOF
        }

#==========================================================================================================
#========= LOCK FILE
#==========================================================================================================
DELETE_LOCK()
        {
                ssh oracle@172.20.11.52 -q 'rm -f /home/oracle/scripts/test.lock' >> ${LOGFILE} 2>&1
        }

#==========================================================================================================
#========= LOGFILE
#==========================================================================================================
APPEND_LOG()
        {
                ssh oracle@172.20.11.52 "cat >> /home/oracle/scripts/logs/log_data_transfer_`date +%Y%m%d`.log" < ${LOGFILE}
                echo -e "" >> ${LOGFILE} 2>&1
        }

#==========================================================================================================
#========= MANAGE FILES
#==========================================================================================================
DEL_DMP()
        {
                rm -f /archive1/dumps3/ST_*.dmp /archive1/dumps3/AT_*.dmp
        }

MOVE_LOG()
        {
                mv /archive1/dumps3/IMP_*.log /archive1/dumps3/logs/
        }

#==========================================================================================================
#========= FUNCTION WRAP
#==========================================================================================================
# RUN INSERT
EXEC_INSERT()
        {
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE INSERT ON ${INSTANCE} STARTED." >> ${LOGFILE} 2>&1
                FN_INSERT
        }

# EMAIL LOGFILE
EMAIL_FAIL()
        {
                echo -e "Data transfer process FAILED.\n\nPlease check the attached log." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - FAILED" -a ${EMAIL_LOG} 'rafael.oliveira@digicelgroup.com' ${EMAIL}
        }

# EXECUTE SCRIPT
RUN_SCRIPT()
        {
        EXEC_IMP
        if [[ "$(grep -c "successfully completed" /archive1/dumps3/scripts/logs/log_data_transfer_`date +%Y%m%d`.log)" == 11 ]]
        then
                echo -e "" >> ${LOGFILE} 2>&1
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE IMPORT FINISHED." >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                EXEC_INSERT
                #if [[ "$?" -eq "0" ]]
                if [[ "$(grep -c "ERROR:" /archive1/dumps3/scripts/logs/log_data_transfer_`date +%Y%m%d`.log)" == "0" ]]
                then
                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE INSERT FINISHED." >> ${LOGFILE} 2>&1
                        echo -e "" >> ${LOGFILE} 2>&1
                        DEL_DMP
                        if [[ "ls /archive1/dumps3/ST_*.dmp 2> /dev/null | wc -l == "0"" && "ls /archive1/dumps3/AT_*.dmp 2> /dev/null | wc -l == "0"" ]]
                        then
                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE DUMPS DELETED." >> ${LOGFILE} 2>&1
                                echo -e "" >> ${LOGFILE} 2>&1
                                MOVE_LOG
                                if [[ "ls /archive1/dumps3/IMP_*.log 2> /dev/null | wc -l == "0"" ]]
                                then
                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE LOGS MOVED." >> ${LOGFILE} 2>&1
                                        echo -e "" >> ${LOGFILE} 2>&1
                                else
                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE LOGS NOT MOVED." >> ${LOGFILE} 2>&1
                                        echo -e "" >> ${LOGFILE} 2>&1
                                        echo -e "!! MOVE ERROR !!" >> ${LOGFILE} 2>&1
                                        EMAIL_FAIL
                                        exit 1;
                                fi
                        else
                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE DUMPS NOT FINISHED." >> ${LOGFILE} 2>&1
                                echo -e "" >> ${LOGFILE} 2>&1
                                echo -e "!! DELETE ERROR !!" >> ${LOGFILE} 2>&1
                                EMAIL_FAIL
                                exit 1;
                        fi
                else
                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE INSERT NOT FINISHED." >> ${LOGFILE} 2>&1
                        echo -e "" >> ${LOGFILE} 2>&1
                        echo -e "!! INSERT ERROR !!" >> ${LOGFILE} 2>&1
                        EMAIL_FAIL
                        exit 1;
                fi
        else
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] IMPORT NOT FINISHED." >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                echo -e "!! IMPORT ERROR !!" >> ${LOGFILE} 2>&1
                EMAIL_FAIL
                DEL_DMP
                rm -f /archives/dumps3/IMP_*.log
                exit 1;
        fi
        DELETE_LOCK
        if [[ $(ssh oracle@172.20.11.52 ls /home/oracle/scripts/test.lock 2> /dev/null | wc -l) == "0" ]]
        then
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCK FILE REMOVED." >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
        else
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCK FILE NOT REMOVED." >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                echo -e "!! LOCK FILE ERROR !!" >> ${LOGFILE} 2>&1
                EMAIL_FAIL
                exit 1;
        fi
        APPEND_LOG
        }

#==========================================================================================================
#========= EXECUTION CONTROL
#==========================================================================================================
RUN_SCRIPT
