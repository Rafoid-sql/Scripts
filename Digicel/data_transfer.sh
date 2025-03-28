#set -x
#!/bin/bash
#==========================================================================================================
#    Author: Rafael Oliveira
#   Summary: Automated execution for the Data Transfer process
#==========================================================================================================

#==========================================================================================================
#========= VARIABLES
#==========================================================================================================

# ORACLE
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/18.0.0/db18c
export ORACLE_SID=TTCDRMSC
export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$ORACLE_HOME/bin

# CREDENTIALS
export EMAIL=''COE_DBA@DIGICELGROUP.COM' 'TNT_IT_DWH@DIGICELGROUP.COM''

# DATE
DT_CDRMSC=`date -d "1 days ago" +%b%d`
DT_OTHERS=`date -d "2 days ago" +%b%d`
YR_CDRMSC=`date -d "1 days ago" +%Y%m`
YR_OTHERS=`date -d "2 days ago" +%Y%m`
FD_CDRMSC=`date -d "1 days ago" +%Y%m%d`
FD_OTHERS=`date -d "2 days ago" +%Y%m%d`

# PARFILE
PAR_FOLDER_REM='/archive1/dumps3/parfile'

# DUMP
DMP_FOLDER_REM='/archive1/dumps3'

# LOGS
LOG_FOLDER='/home/oracle'

# LOGFILE
touch /home/oracle/scripts/logs/log_data_transfer_`date +%Y%m%d`.log
LOGFILE=/home/oracle/scripts/logs/log_data_transfer_`date +%Y%m%d`.log
EMAIL_LOG=`ls /home/oracle/scripts/logs/log_data_transfer_*.log | tail -1`

#==========================================================================================================
#========= CDRMSC FUNCTION
#==========================================================================================================
# EXPDP
FN_EXP_CDRMSC_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_st_cdrmsc_import.par
                directory=DATA_DUMPS
                dumpfile=ST_CDRMSC_IMPORT_${DT_CDRMSC}_%u.dmp
                logfile=EXP_ST_CDRMSC_IMPORT_${DT_CDRMSC}.log
                parallel=5
                exclude=statistics
                exclude=INDEX
                #reuse_dumpfiles=YES
                tables=CDRMSC.ST_CDRMSC_IMPORT:PART_${FD_CDRMSC}
                EOF
        }

# IMPDP
FN_IMP_CDRMSC_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_cdrmsc.par
                tables=CDRMSC.ST_CDRMSC_IMPORT:PART_${FD_CDRMSC}
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=ST_CDRMSC_IMPORT_${DT_CDRMSC}_%u.dmp
                logfile=IMP_ST_CDRMSC_IMPORT_${DT_CDRMSC}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

#==========================================================================================================
#========= CDRUSSDMSC FUNCTION
#==========================================================================================================
# EXPDP
FN_EXP_CDRUSSDMSC_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_st_cdrussd_import.par
                directory=DATA_DUMPS
                dumpfile=ST_CDRUSSD_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=EXP_ST_CDRUSSD_IMPORT_${DT_OTHERS}.log
                parallel=4
                exclude=statistics
                reuse_dumpfiles=Y
                tables=CDRMSC.ST_CDRUSSDMSC_IMPORT:PART_${FD_OTHERS}
                EOF
        }

FN_EXP_CDRUSSDMSC_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_at_cdrussd_loaded.par
                directory=DATA_DUMPS
                dumpfile=AT_CDRUSSD_LOADED_${DT_OTHERS}_%u.dmp
                logfile=EXP_AT_CDRUSSD_LOADED_${DT_OTHERS}.log
                parallel=4
                exclude=statistics,INDEX
                reuse_dumpfiles=Y
                tables=CDRMSC.AT_CDRUSSDMSC_LOADED
                query=CDRMSC.AT_CDRUSSDMSC_LOADED:"where date_call ='${FD_OTHERS}'"
                EOF
        }

# IMPDP
FN_IMP_CDRUSSDMSC_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_st_cdrussd_import.par
                tables=CDRMSC.ST_CDRUSSDMSC_IMPORT
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=ST_CDRUSSD_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=IMP_ST_CDRUSSD_IMPORT_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

FN_IMP_CDRUSSDMSC_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_at_cdrussd_loaded.par
                tables=CDRMSC.AT_CDRUSSDMSC_LOADED
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=AT_CDRUSSD_LOADED_${DT_OTHERS}_%u.dmp
                logfile=IMP_AT_CDRUSSD_LOADED_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

#==========================================================================================================
#========= PSL BONUS ADJUSTMENTS FUNCTION
#==========================================================================================================
# EXPDP
FN_EXP_PSL_BON_ADJ_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_st_cdrpsl_impbonus_adj.par
                directory=DATA_DUMPS
                dumpfile=ST_CDRPSL_IMPADJT_${DT_OTHERS}_%u.dmp
                logfile=EXP_ST_CDRPSL_IMPADJT_${DT_OTHERS}.log
                parallel=4
                exclude=statistics
                reuse_dumpfiles=YES
                tables=CDRPSL.ST_CDRPSL_IMPORT_BONUSADJT:PART_${FD_OTHERS}
                EOF
        }

FN_EXP_PSL_BON_ADJ_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_at_cdrpsl_bon_adjt.par
                directory=DATA_DUMPS
                dumpfile=AT_CDRPSL_BONADJT_${DT_OTHERS}_%u.dmp
                logfile=EXP_AT_CDRPSL_BONADJT_${DT_OTHERS}.log
                parallel=4
                exclude=statistics
                reuse_dumpfiles=YES
                tables=CDRPSL.AT_CDRPSL_LOADED_BONUSADJT
                query=CDRPSL.AT_CDRPSL_LOADED_BONUSADJT:"where date_call ='${FD_OTHERS}'"
                EOF
        }

# IMPDP
FN_IMP_PSL_BON_ADJ_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_st_cdrpsl_imp_bonadjt.par
                tables=CDRPSL.ST_CDRPSL_IMPORT_BONUSADJT
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=ST_CDRPSL_IMPADJT_${DT_OTHERS}_%u.dmp
                logfile=IMP_ST_CDRPSL_IMPADJT_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

FN_IMP_PSL_BON_ADJ_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_at_cdrpsl_load_bonadjt.par
                tables=CDRPSL.AT_CDRPSL_LOADED_BONUSADJT
                content=data_only
                table_exists_action=append
                parallel=4
                dumpfile=AT_CDRPSL_BONADJT_${DT_OTHERS}_%u.dmp
                logfile=IMP_AT_CDRPSL_BONADJT_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

#==========================================================================================================
#========= LTE ROAMERS FUNCTION
#==========================================================================================================
# EXPDP
FN_EXP_LTER_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_st_lte_roam_loaded.par
                directory=DATA_DUMPS
                dumpfile=ST_LTE_ROAMERS_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=EXP_ST_LTE_ROAMERS_IMPORT_${DT_OTHERS}.log
                parallel=5
                exclude=statistics
                exclude=INDEX
                #reuse_dumpfiles=YES
                tables=ROAMBROKER.ST_LTE_ROAMERS_IMPORT:PART_${YR_OTHERS}
                query=ROAMBROKER.ST_LTE_ROAMERS_IMPORT:"where date_code ='${FD_OTHERS}'"
                EOF
        }

FN_EXP_LTER_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_at_lte_roam_loaded.par
                directory=DATA_DUMPS
                dumpfile=AT_LTE_ROAMERS_LOADED_${DT_OTHERS}_%u.dmp
                logfile=EXP_AT_LTE_ROAMERS_LOADED_${DT_OTHERS}.log
                parallel=4
                exclude=statistics,INDEX
                reuse_dumpfiles=Y
                tables=ROAMBROKER.AT_LTE_ROAMERS_LOADED
                query=CDRMSC.AT_CDRUSSDMSC_LOADED:"where date_call ='${FD_OTHERS}'"
                EOF
        }

# IMPDP
FN_IMP_LTER_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_st_lte_roam_import.par
                tables=ROAMBROKER.ST_LTE_ROAMERS_IMPORT
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=ST_LTE_ROAMERS_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=IMP_ST_LTE_ROAMERS_IMPORT_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

FN_IMP_LTER_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_at_lte_roam_loaded.par
                tables=ROAMBROKER.AT_LTE_ROAMERS_LOADED
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=AT_LTE_ROAMERS_LOADED_${DT_OTHERS}_%u.dmp
                logfile=IMP_AT_LTE_ROAMERS_LOADED_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

#==========================================================================================================
#========= RB GPRS FUNCTION
#==========================================================================================================
# EXPDP
FN_EXP_RBGPRS_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_st_rbgprs_import.par
                directory=DATA_DUMPS
                dumpfile=ST_RBGPRS_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=EXP_ST_RBGPRS_IMPORT_${DT_OTHERS}.log
                parallel=5
                exclude=statistics
                exclude=INDEX
                #reuse_dumpfiles=YES
                tables=ROAMBROKER.ST_RBGPRS_IMPORT:PART_${YR_OTHERS}
                query=ROAMBROKER.ST_RBGPRS_IMPORT:"where date_code ='${FD_OTHERS}'"
                EOF
        }

FN_EXP_RBGPRS_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_at_rbgprs_loaded.par
                directory=DATA_DUMPS
                dumpfile=AT_RBGPRS_LOADED_${DT_OTHERS}_%u.dmp
                logfile=EXP_AT_RBGPRS_LOADED_${DT_OTHERS}.log
                parallel=4
                exclude=statistics,INDEX
                reuse_dumpfiles=Y
                tables=ROAMBROKER.AT_RBGPRS_LOADED
                query=ROAMBROKER.AT_RBGPRS_LOADED:"where date_call ='${FD_OTHERS}'"
                EOF
        }

# IMPDP
FN_IMP_RBGPRS_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_st_rbgprs_import.par
                tables=ROAMBROKER.ST_RBGPRS_IMPORT
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=ST_RBGPRS_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=IMP_ST_RBGPRS_IMPORT_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

FN_IMP_RBGPRS_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_at_rbgprs_loaded.par
                tables=ROAMBROKER.AT_RBGPRS_LOADED
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=AT_RBGPRS_LOADED_${DT_OTHERS}_%u.dmp
                logfile=IMP_AT_RBGPRS_LOADED_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

#==========================================================================================================
#========= RB VOICE FUNCTION
#==========================================================================================================
# EXPDP
FN_EXP_RBVOICE_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_st_rbvoice_import.par
                directory=DATA_DUMPS
                dumpfile=ST_RBVOICE_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=EXP_ST_RBVOICE_IMPORT_${DT_OTHERS}.log
                parallel=5
                exclude=statistics
                exclude=INDEX
                #reuse_dumpfiles=YES
                tables=ROAMBROKER.ST_RBVOICE_IMPORT:PART_${FD_OTHERS}
                EOF
        }

FN_EXP_RBVOICE_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/exp_at_rbvoice_loaded.par
                directory=DATA_DUMPS
                dumpfile=AT_RBVOICE_LOADED_${DT_OTHERS}_%u.dmp
                logfile=EXP_AT_RBVOICE_LOADED_${DT_OTHERS}.log
                parallel=4
                exclude=statistics,INDEX
                reuse_dumpfiles=Y
                tables=ROAMBROKER.AT_RBVOICE_LOADED
                query=ROAMBROKER.AT_RBVOICE_LOADED:"where date_call ='${FD_OTHERS}'"
                EOF
        }

# IMPDP
FN_IMP_RBVOICE_ST()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_st_rbvoice_import.par
                tables=ROAMBROKER.ST_RBVOICE_IMPORT:PART_${FD_OTHERS}
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=ST_RBVOICE_IMPORT_${DT_OTHERS}_%u.dmp
                logfile=IMP_ST_RBVOICE_IMPORT_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

FN_IMP_RBVOICE_AT()
        {
                cat >> ${LOGFILE} 2>&1 <<-EOF >> /home/oracle/parfile/imp_at_rbvoice_loaded.par
                tables=ROAMBROKER.AT_RBVOICE_LOADED
                content=data_only
                table_exists_action=append
                parallel=5
                dumpfile=AT_RBVOICE_LOADED_${DT_OTHERS}_%u.dmp
                logfile=IMP_AT_RBVOICE_LOADED_${DT_OTHERS}.log
                directory=ARCHIVE1_DUMPS
                EOF
        }

#==========================================================================================================
#========= EXECUTE DATAPUMP
#==========================================================================================================
EXEC_EXP()
        {
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPORT STARTED." >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_st_cdrmsc_import.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_st_cdrpsl_impbonus_adj.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_st_cdrussd_import.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_st_lte_roam_loaded.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_st_rbgprs_import.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_st_rbvoice_import.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_at_cdrpsl_bon_adjt.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_at_cdrussd_loaded.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_at_lte_roam_loaded.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_at_rbgprs_loaded.par >> ${LOGFILE} 2>&1
                expdp system/vpersie#12 parfile=/home/oracle/parfile/exp_at_rbvoice_loaded.par >> ${LOGFILE} 2>&1
        }

#==========================================================================================================
#========= CALL REMOTE SCRIPT
#==========================================================================================================
REMOTE_EXEC()
        {
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE EXECUTION STARTED." >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                ssh oracle@172.20.10.20 "/archive1/dumps3/scripts/import_insert.sh"
                wait
        }

#==========================================================================================================
#========= MANAGE FILES
#==========================================================================================================
# TTCDRMSC
DEL_LOC_PAR()
        {
                rm -f /home/oracle/parfile/*.par
        }

DEL_LOC_DMP()
        {
                rm -f /home/oracle/ST_*.dmp AT_*.dmp
        }

MOVE_LOC_LOG()
        {
                mv /home/oracle/EXP_*.log /home/oracle/logs/
        }

# TTDWH004
DEL_REM_PAR()
        {
                ssh oracle@172.20.10.20 'rm -f /archive1/dumps3/parfile/imp_*.par'
        }

COPY_REM_PAR()
        {
                scp /home/oracle/parfile/imp_*.par  oracle@172.20.10.20:/archive1/dumps3/parfile/
                rm -f /home/oracle/parfile/imp_*.par
        }

COPY_REM_DMP()
        {
                scp /home/oracle/*.dmp  oracle@172.20.10.20:/archive1/dumps3/
        }

#==========================================================================================================
#========= LOGFILE
#==========================================================================================================
CREATE_LOG()
        {
                touch /home/oracle/scripts/logs/log_data_transfer_`date +%Y%m%d`.log >> ${LOGFILE} 2>&1
        }

#==========================================================================================================
#========= LOCK FILE
#==========================================================================================================
CREATE_LOCK()
        {
                touch /home/oracle/scripts/test.lock >> ${LOGFILE} 2>&1
        }

#==========================================================================================================
#========= FUNCTION WRAP
#==========================================================================================================
# EXPDP
CREATE_EXP()
        {
                FN_EXP_CDRMSC_ST
                FN_EXP_CDRUSSDMSC_ST
                FN_EXP_PSL_BON_ADJ_ST
                FN_EXP_LTER_ST
                FN_EXP_RBGPRS_ST
                FN_EXP_RBVOICE_ST
                FN_EXP_CDRUSSDMSC_AT
                FN_EXP_PSL_BON_ADJ_AT
                FN_EXP_LTER_AT
                FN_EXP_RBGPRS_AT
                FN_EXP_RBVOICE_AT
        }

# IMPDP
CREATE_IMP()
        {
                FN_IMP_CDRMSC_ST
                FN_IMP_CDRUSSDMSC_ST
                FN_IMP_PSL_BON_ADJ_ST
                FN_IMP_LTER_ST
                FN_IMP_RBGPRS_ST
                FN_IMP_RBVOICE_ST
                FN_IMP_CDRUSSDMSC_AT
                FN_IMP_PSL_BON_ADJ_AT
                FN_IMP_LTER_AT
                FN_IMP_RBGPRS_AT
                FN_IMP_RBVOICE_AT
        }

# DELETE PARFILES
DEL_PAR()
        {
                DEL_LOC_PAR
                DEL_REM_PAR
        }

# COPY REMOTE FILES
COPY_FILE()
        {
                COPY_REM_PAR
                COPY_REM_DMP
        }

# EMAIL LOGFILE
EMAIL_BEGIN()
        {
                echo -e "Data transfer process STARTED.\n\nLog created in ${EMAIL_LOG} on `hostname`." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - STARTED" 'rafael.oliveira@digicelgroup.com' ${EMAIL}
        }

EMAIL_SUCCESS()
        {
                echo -e "Data transfer process FINISHED.\n\nOperation log attached." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - FINISHED" -a ${EMAIL_LOG} 'rafael.oliveira@digicelgroup.com' ${EMAIL}
        }

EMAIL_FAIL()
        {
                echo -e "Data transfer process FAILED.\n\nPlease check the attached log." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - FAILED" -a ${EMAIL_LOG} 'rafael.oliveira@digicelgroup.com' ${EMAIL}
        }

# EXECUTE SCRIPT
RUN_SCRIPT()
        {
        CREATE_LOG
        if ping -c 1 172.20.10.20 &> /dev/null
        then
                echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] STARTING DATA TRANSFER PROCESS:" >> ${LOGFILE} 2>&1
                echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                EMAIL_BEGIN
                DEL_PAR
                if [[ "$(ls -A /home/oracle/parfile/*.par 2>/dev/null)" == ""  && "$(ssh oracle@172.20.10.20 ls -A /archive1/dumps3/parfile/*.par 2>/dev/null)" == "" ]]
                then
                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] OLD PARFILES DELETED." >> ${LOGFILE} 2>&1
                        echo -e "" >> ${LOGFILE} 2>&1
                        CREATE_EXP
                        if [[ "$(ls /home/oracle/parfile/exp_*.par 2> /dev/null | wc -l)" == "11" ]]
                        then
                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPDP FILES CREATED." >> ${LOGFILE} 2>&1
                                echo -e "" >> ${LOGFILE} 2>&1
                                CREATE_IMP
                                if [[ "$(ls /home/oracle/parfile/imp_*.par 2> /dev/null | wc -l)" == "11" ]]
                                then
                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] IMPDP FILES CREATED." >> ${LOGFILE} 2>&1
                                        echo -e "" >> ${LOGFILE} 2>&1
                                        EXEC_EXP
                                        if [[ "$(grep -c "successfully completed" /home/oracle/scripts/logs/log_data_transfer_`date +%Y%m%d`.log)" == "11" ]]
                                        then
                                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPORT FINISHED." >> ${LOGFILE} 2>&1
                                                echo -e "" >> ${LOGFILE} 2>&1
                                                CNT=`ls /home/oracle/ST_*.dmp /home/oracle/AT_*.dmp 2> /dev/null | wc -l`
                                                COPY_FILE
                                                if [[ "$(ssh oracle@172.20.10.20 ls /archive1/dumps3/parfile/*.par 2> /dev/null | wc -l)" == "11" && "$(ssh oracle@172.20.10.20 ls /archive1/dumps3/ST_*.dmp /archive1/dumps3/AT_*.dmp 2> /dev/null | wc -l)" == "${CNT}" ]]
                                                then
                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] FILES COPIED TO REMOTE SERVER." >> ${LOGFILE} 2>&1
                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                        CREATE_LOCK
                                                        if [[ -f /home/oracle/scripts/test.lock ]]
                                                        then
                                                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCK FILE CREATED." >> ${LOGFILE} 2>&1
                                                                echo -e "" >> ${LOGFILE} 2>&1
                                                                REMOTE_EXEC
                                                                sleep 10
                                                                if [[ ! -f /home/oracle/scripts/test.lock ]]
                                                                then
                                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE EXECUTION FINISHED." >> ${LOGFILE} 2>&1
                                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                                        DEL_LOC_DMP
                                                                        if [[ "$(ls /home/oracle/ST_*.dmp /home/oracle/AT_*.dmp 2> /dev/null | wc -l)" == "0" ]]
                                                                        then
                                                                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCAL DUMPS DELETED." >> ${LOGFILE} 2>&1
                                                                                echo -e "" >> ${LOGFILE} 2>&1
                                                                                MOVE_LOC_LOG
                                                                                if [[ "ls /home/oracle/EXP_*.log 2> /dev/null | wc -l == "0"" ]]
                                                                                then
                                                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCAL LOGS MOVED." >> ${LOGFILE} 2>&1
                                                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                                                        echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
                                                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] DATA TRANSFER PROCESS FINISHED." >> ${LOGFILE} 2>&1
                                                                                        echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
                                                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                                                        EMAIL_SUCCESS
                                                                                        exit;
                                                                                else
                                                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCAL LOGS NOT MOVED." >> ${LOGFILE} 2>&1
                                                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                                                        echo -e "!! MOVE ERROR !!" >> ${LOGFILE} 2>&1
                                                                                        EMAIL_FAIL
                                                                                        exit 1;
                                                                                fi
                                                                        else
                                                                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCAL DUMPS NOT DELETED." >> ${LOGFILE} 2>&1
                                                                                echo -e "" >> ${LOGFILE} 2>&1
                                                                                echo -e "!! DELETION ERROR !!" >> ${LOGFILE} 2>&1
                                                                                EMAIL_FAIL
                                                                                exit 1;
                                                                        fi
                                                                else
                                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] REMOTE EXECUTION FAILED." >> ${LOGFILE} 2>&1
                                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                                        echo -e "!! EXECUTION ERROR !!" >> ${LOGFILE} 2>&1
                                                                        EMAIL_FAIL
                                                                        exit 1;
                                                                fi
                                                        else
                                                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOCK FILE NOT CREATED." >> ${LOGFILE} 2>&1
                                                                echo -e "" >> ${LOGFILE} 2>&1
                                                                echo -e "!! LOCK FILE ERROR !!" >> ${LOGFILE} 2>&1
                                                                EMAIL_FAIL
                                                                exit 1;
                                                        fi
                                                else
                                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] FILES NOT COPIED." >> ${LOGFILE} 2>&1
                                                        echo -e "" >> ${LOGFILE} 2>&1
                                                        echo -e "!! FILE COPY ERROR !!" >> ${LOGFILE} 2>&1
                                                        EMAIL_FAIL
                                                        exit 1;
                                                fi
                                        else
                                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPORT NOT FINISHED." >> ${LOGFILE} 2>&1
                                                echo -e "" >> ${LOGFILE} 2>&1
                                                echo -e "!! EXPORT ERROR !!" >> ${LOGFILE} 2>&1
                                                EMAIL_FAIL
                                                rm -f /home/oracle/EXP_*.log
                                                DEL_LOC_DMP
                                                exit 1;
                                        fi
                                else
                                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] IMPDP FILES NOT CREATED." >> ${LOGFILE} 2>&1
                                        echo -e "" >> ${LOGFILE} 2>&1
                                        echo -e "!! IMPORT PARFILE CREATION ERROR !!" >> ${LOGFILE} 2>&1
                                        EMAIL_FAIL
                                        exit 1;
                                fi
                        else
                                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPDP FILES NOT CREATED." >> ${LOGFILE} 2>&1
                                echo -e "" >> ${LOGFILE} 2>&1
                                echo -e "!! EXPORT PARFILE CREATION ERROR !!" >> ${LOGFILE} 2>&1
                                EMAIL_FAIL
                                exit 1;
                        fi
                else
                        echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] OLD PARFILES NOT DELETED." >> ${LOGFILE} 2>&1
                        echo -e "" >> ${LOGFILE} 2>&1
                        echo -e "!! PARFILE DELETION ERROR !!" >> ${LOGFILE} 2>&1
                        EMAIL_FAIL
                        exit 1;
                fi
        else
                echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] CONNECTION FAILED." >> ${LOGFILE} 2>&1
                echo -e "" >> ${LOGFILE} 2>&1
                echo -e "!! ${INSTANCE} UNREACHABLE !!" >> ${LOGFILE} 2>&1
                EMAIL_FAIL
                exit 1;
        fi
        }

#==========================================================================================================
#========= EXECUTION CONTROL
#==========================================================================================================
RUN_SCRIPT
