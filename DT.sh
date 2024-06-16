#set -x
#!/bin/bash
#==========================================================================================================
#    Author: Rafael Oliveira
#   Summary: Automated execution for the Data Transfer process
###########################################################################################################
# Changelog:
# - 06/13/2024: Headers and logfile texts inserted.
# - 06/14/2024: Execution control and error handling finished.
#==========================================================================================================

#==========================================================================================================
#========= VARIABLES
#==========================================================================================================

# INSTANCE
#export INSTANCE=`ps -ef | grep ora_pmon_| grep -v grep | awk -F_ '{print $3}'`
export INSTANCE=TTDWH004
export USER_PROXY=ROLIVEIRA
export USER_PROXY_PWD='"Airbus#01"'

# DATE
DT_CDRMSC=`date -d "1 days ago" +%b%d`
DT_OTHERS=`date -d "2 days ago" +%b%d`
YR_CDRMSC=`date -d "1 days ago" +%Y%m`
YR_OTHERS=`date -d "2 days ago" +%Y%m`
FD_CDRMSC=`date -d "1 days ago" +%Y%m%d`
FD_OTHERS=`date -d "2 days ago" +%Y%m%d`

# PARFILE
SCR_FOLDER='/home/oracle/scripts'
PAR_FOLDER_LOC='/home/oracle/parfile'
PAR_FOLDER_REM='/archive1/dumps3/parfile'

# DUMP
DMP_FOLDER_LOC='/home/oracle'
DMP_FOLDER_REM='/archive1/dumps3'

# LOGS
LOG_FOLDER_LOC='/home/oracle'
LOG_FOLDER_REM='/archive1/dumps3'

# LOGFILE
LOGFILE=${SCR_FOLDER}/log_data_transfer_`date +%Y%m%d_%H%M%S`.log


#==========================================================================================================
#========= CDRMSC FUNCTION
#==========================================================================================================

# EXPDP
FN_EXP_CDRMSC_ST()
	{
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_st_cdrmsc_import.par
		directory=DATA_DUMPS
		dumpfile=ST_CDRMSC_IMPORT_${DT_CDRMSC}_%u.dmp
		logfile=ST_CDRMSC_IMPORT_${DT_CDRMSC}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_cdrmsc.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_st_cdrussd_import.par
		directory=DATA_DUMPS
		dumpfile=ST_CDRUSSD_IMPORT_${DT_OTHERS}_%u.dmp
		logfile=ST_CDRUSSD_IMPORT_${DT_OTHERS}.log
		parallel=4
		exclude=statistics
		reuse_dumpfiles=Y
		tables=CDRMSC.ST_CDRUSSDMSC_IMPORT:PART_${FD_OTHERS}
		EOF
	}

FN_EXP_CDRUSSDMSC_AT()
	{
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_at_cdrussd_loaded.par
		directory=DATA_DUMPS
		dumpfile=AT_CDRUSSD_LOADED_${DT_OTHERS}_%u.dmp
		logfile=AT_CDRUSSD_LOADED_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_st_cdrussd_import.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_at_cdrussd_loaded.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_st_cdrpsl_impbonus_adj.par
		directory=DATA_DUMPS
		dumpfile=ST_CDRPSL_IMPADJT_${DT_OTHERS}_%u.dmp
		logfile=ST_CDRPSL_IMPADJT_${DT_OTHERS}.log
		parallel=4
		exclude=statistics
		reuse_dumpfiles=YES
		tables=CDRPSL.ST_CDRPSL_IMPORT_BONUSADJT:PART_${FD_OTHERS}
		EOF
	}

FN_EXP_PSL_BON_ADJ_AT()
	{
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_at_cdrpsl_bon_adjt.par
		directory=DATA_DUMPS
		dumpfile=AT_CDRPSL_BONADJT_${DT_OTHERS}_%u.dmp
		logfile=AT_CDRPSL_BONADJT_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_st_cdrpsl_imp_bonadjt.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_at_cdrpsl_load_bonadjt.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_st_lte_roam_loaded.par
		directory=DATA_DUMPS
		dumpfile=ST_LTE_ROAMERS_IMPORT_${DT_OTHERS}_%u.dmp
		logfile=ST_LTE_ROAMERS_IMPORT_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_at_lte_roam_loaded.par
		directory=DATA_DUMPS
		dumpfile=AT_LTE_ROAMERS_LOADED_${DT_OTHERS}_%u.dmp
		logfile=AT_LTE_ROAMERS_LOADED_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_st_lte_roam_import.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_at_lte_roam_loaded.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_st_rbgprs_import.par
		directory=DATA_DUMPS
		dumpfile=ST_RBGPRS_IMPORT_${DT_OTHERS}_%u.dmp
		logfile=ST_RBGPRS_IMPORT_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_at_rbgprs_loaded.par
		directory=DATA_DUMPS
		dumpfile=AT_RBGPRS_LOADED_${DT_OTHERS}_%u.dmp
		logfile=AT_RBGPRS_LOADED_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_st_rbgprs_import.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_at_rbgprs_loaded.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_st_rbvoice_import.par
		directory=DATA_DUMPS
		dumpfile=ST_RBVOICE_IMPORT_${DT_OTHERS}_%u.dmp
		logfile=ST_RBVOICE_IMPORT_${DT_OTHERS}.log
		parallel=5
		exclude=statistics
		exclude=INDEX
		#reuse_dumpfiles=YES
		tables=ROAMBROKER.ST_RBVOICE_IMPORT:PART_${FD_OTHERS}
		EOF
	}

FN_EXP_RBVOICE_AT()
	{
		cat <<-EOF >> ${PAR_FOLDER_LOC}/exp_at_rbvoice_loaded.par
		directory=DATA_DUMPS
		dumpfile=AT_RBVOICE_LOADED_${DT_OTHERS}_%u.dmp
		logfile=AT_RBVOICE_LOADED_${DT_OTHERS}.log
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_st_rbvoice_import.par
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
		cat <<-EOF >> ${PAR_FOLDER_LOC}/imp_at_rbvoice_loaded.par
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
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPORT STARTED:" >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_st_cdrmsc_import.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_st_cdrpsl_impbonus_adj.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_st_cdrussd_import.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_st_lte_roam_loaded.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_st_rbgprs_import.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_st_rbvoice_import.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_at_cdrpsl_bon_adjt.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_at_cdrussd_loaded.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_at_lte_roam_loaded.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_at_rbgprs_loaded.par >> ${LOGFILE} 2>&1
		expdp system/vpersie#11 parfile=${PAR_FOLDER_LOC}/exp_at_rbvoice_loaded.par >> ${LOGFILE} 2>&1
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPORT FINISHED:" >> ${LOGFILE} 2>&1
		echo -e ""
	}

EXEC_IMP()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] IMPORT STARTED:" >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_cdrmsc.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_st_cdrussd_import.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_st_lte_roam_import.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_st_rbgprs_import.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_st_rbvoice_import.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_st_cdrpsl_imp_bonadjt.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_at_cdrpsl_load_bonadjt.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_at_cdrussd_loaded.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_at_lte_roam_loaded.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_at_rbgprs_loaded.par' >> ${LOGFILE} 2>&1
		ssh oracle@172.20.10.20 'impdp 'system/"InfinityEndGame#2019!!!"' parfile=${PAR_FOLDER_LOC}/imp_at_rbvoice_loaded.par' >> ${LOGFILE} 2>&1
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] IMPORT FINISHED:" >> ${LOGFILE} 2>&1
		echo -e ""
	}


#==========================================================================================================
#========= INSERT INTO CDRMSC
#==========================================================================================================
FN_INSERT()
	{
		#ssh oracle@172.20.10.20
		sqlplus ${USER_PROXY}[CDRMSC]/"${USER_PROXY_PWD}"@${INSTANCE} <<-EOF
		whenever sqlerror exit sql.sqlcode ;
		insert into cdrmsc.at_cdrmsc_loaded
		select * from cdrmsc.at_cdrmsc_loaded@TTCDRMSC
		where date_call= '${FD_CDRMSC}'
		and filename not in (select filename from cdrmsc.at_cdrmsc_loaded where date_call= '${FD_CDRMSC}');
		commit;
		quit
		EOF
	}


#==========================================================================================================
#========= MANAGE FILES
#==========================================================================================================

# TTCDRMSC
DEL_LOC_PAR()
	{
		rm -f ${PAR_FOLDER_LOC}/*.par >> ${LOGFILE} 2>&1
	}

DEL_LOC_DMP()
	{
		rm -f ${DMP_FOLDER_LOC}/ST_*.dmp AT_*.dmp >> ${LOGFILE} 2>&1
	}

MOVE_LOC_LOG()
	{
		mv ${LOG_FOLDER_LOC}/ST_*.log ${LOG_FOLDER_LOC}/logs/ >> ${LOGFILE} 2>&1
		mv ${LOG_FOLDER_LOC}/AT_*.log ${LOG_FOLDER_LOC}/logs/ >> ${LOGFILE} 2>&1
		mv ${LOG_FOLDER_LOC}/scripts/log_*.log ${LOG_FOLDER_LOC}/scripts/logs/ >> ${LOGFILE} 2>&1
	}

# TTDWH004
DEL_REM_PAR()
	{
		ssh oracle@172.20.10.20 'rm -f ${PAR_FOLDER_REM}/*.par' >> ${LOGFILE} 2>&1
	}

COPY_REM_PAR()
	{
		scp ${PAR_FOLDER_LOC}/imp_*.par  oracle@172.20.10.20:${PAR_FOLDER_REM}/ >> ${LOGFILE} 2>&1
		rm -f ${PAR_FOLDER_LOC}/imp_*.par
	}

COPY_REM_DMP()
	{
		scp ${DMP_FOLDER_LOC}/*.dmp  oracle@172.20.10.20:${DMP_FOLDER_REM}/ >> ${LOGFILE} 2>&1
	}

DEL_REM_DUMP()
	{
		ssh oracle@172.20.10.20 'rm -f ${DMP_FOLDER_REM}/ST_*.dmp AT_*.dmp' >> ${LOGFILE} 2>&1
	}

MOVE_REM_LOG()
	{
		ssh oracle@172.20.10.20 'mv ${LOG_FOLDER_REM}/imp_*.log ${LOG_FOLDER_REM}/logs/' >> ${LOGFILE} 2>&1
	}


#==========================================================================================================
#========= FUNCTION WRAP
#==========================================================================================================

# EXPDP
CREATE_EXP()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] CREATING EXPDP FILES:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
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
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EXPDP FILES CREATED." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# IMPDP
CREATE_IMP()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] CREATING IMPDP FILES:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
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
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] IMPDP FILES CREATED." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# DELETE PARFILES
DEL_PAR()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] DELETING OLD PARFILES:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		DEL_LOC_PAR >> ${LOGFILE} 2>&1
		DEL_REM_PAR >> ${LOGFILE} 2>&1
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] OLD PARFILES DELETED." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# COPY REMOTE FILES
COPY_FILE()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] COPYING FILES TO REMOTE SERVER:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		COPY_REM_PAR
		COPY_REM_DMP
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] FILES COPIED." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# DELETE DUMPS
DEL_FILE()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] DELETING DUMPFILES:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		DEL_LOC_DMP
		DEL_REM_DMP
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] DUMPFILES DELETED." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# MOVE LOGS
MOVE_LOG()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] MOVING LOGFILES:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		MOVE_LOC_LOG
		MOVE_REM_LOG
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] LOGFILES MOVED." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# RUN INSERT
EXEC_INSERT()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] RUNNING INSERT ON ${INSTANCE}:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		FN_INSERT
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] INSERT RAN SUCCESSFULLY." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

# EMAIL LOGFILE
EMAIL_LOG_BEGIN()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] SENDING START EMAIL:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		echo -e "Data transfer process STARTED.\n\nLog created in /home/oracle/scripts/`basename /home/oracle/scripts/log_*` on `hostname`." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - STARTED" 'COE_DBA@DIGICELGROUP.COM' 'TNT_IT_DWH@DIGICELGROUP.COM'
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EMAIL SENT." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}

EMAIL_LOG_SUCCESS()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] SENDING FINISH EMAIL:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		echo -e "Data transfer process FINISHED.\n\nOperation log attached, or check /home/oracle/scripts/`basename /home/oracle/scripts/log_*` on `hostname`." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - FINISHED" -a `basename /home/oracle/scripts/log_*` 'COE_DBA@DIGICELGROUP.COM' 'TNT_IT_DWH@DIGICELGROUP.COM'
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EMAIL SENT." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}
	
EMAIL_LOG_FAIL()
	{
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] SENDING FAIL EMAIL:" >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
		echo -e "Data transfer process FAILED.\n\nFor more information, please check the attached log or access /home/oracle/scripts/`basename /home/oracle/scripts/log_*` on `hostname`." | mail -s "DATA TRANSFER `date +%m/%d/%Y` - FAILED" -a `basename /home/oracle/scripts/log_*` 'COE_DBA@DIGICELGROUP.COM' 'TNT_IT_DWH@DIGICELGROUP.COM'
		echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] EMAIL SENT." >> ${LOGFILE} 2>&1
		echo -e "" >> ${LOGFILE} 2>&1
	}


#==========================================================================================================
#========= EXECUTION CONTROL
#==========================================================================================================

if ping -c 1 172.20.10.20 &> /dev/null
then
	echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
	echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] STARTING DATA TRANSFER PROCESS:" >> ${LOGFILE} 2>&1
	echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
	echo -e "" >> ${LOGFILE} 2>&1
	EMAIL_LOG_BEGIN
	DEL_PAR
	if [[ "$(ls -A ${PAR_FOLDER_LOC}/*.par 2>/dev/null)" == ""  && "$(ssh oracle@172.20.10.20 ls -A ${PAR_FOLDER_REM}/*.par 2>/dev/null)" == "" ]]
	then
		CREATE_EXP
		CREATE_IMP
		if [[ "$(ls ${PAR_FOLDER_LOC}/imp_*.par | wc -l)" == "11" && "$(ls ${PAR_FOLDER_LOC}/exp_*.par | wc -l)" == "11" ]]
		then
			EXEC_EXP
			if [[ `grep -c "successfully completed" ${SCR_FOLDER}/`basename ${SCR_FOLDER}/log_*`` == "11" ]];
			then
				CNT=`ls ${DMP_FOLDER_LOC}/*.dmp | wc -l`
				COPY_FILE
				if [[ "$(ssh oracle@172.20.10.20 ls ${PAR_FOLDER_REM}/*.par | wc -l)" == "11" && "$(ssh oracle@172.20.10.20 ls ${DMP_FOLDER_REM}/*.dmp | wc -l)" == "${CNT}" ]]
				then
					EXEC_IMP
					if [[ `grep -c "successfully completed" ${SCR_FOLDER}/`basename ${SCR_FOLDER}/log_*`` == "22" ]];
					then
						EXEC_INSERT
						if [[ $? -eq 0 ]]
						then
							DEL_FILE
							if [[ "$(${DMP_FOLDER_LOC}/*.dmp | wc -l)" == "" && "$(ssh oracle@172.20.10.20 ls ${DMP_FOLDER_REM}/*.dmp | wc -l)" == "" ]]
							then
								MOVE_LOG
								echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
								echo -e "## [`date +"%m-%d-%Y %H:%M:%S"`] DATA TRANSFER PROCESS FINISHED." >> ${LOGFILE} 2>&1
								echo -e "#############################################################################################" >> ${LOGFILE} 2>&1
								EMAIL_LOG_SUCCESS
								exit;
							else
								echo -e "" >> ${LOGFILE} 2>&1
								echo -e "!! DELETION ERROR !!" >> ${LOGFILE} 2>&1
								EMAIL_LOG_FAIL
								exit 1;
							fi
						else
							echo -e "" >> ${LOGFILE} 2>&1
							echo -e "!! INSERT ERROR !!" >> ${LOGFILE} 2>&1
							EMAIL_LOG_FAIL
							exit 1;
						fi
					else
						echo -e "" >> ${LOGFILE} 2>&1
						echo -e "!! IMPORT ERROR !!" >> ${LOGFILE} 2>&1
						EMAIL_LOG_FAIL
						exit 1;
					fi
				else
					echo -e "" >> ${LOGFILE} 2>&1
					echo -e "!! COPY ERROR !!" >> ${LOGFILE} 2>&1
					EMAIL_LOG_FAIL
					exit 1;
				fi
			else
				echo -e "" >> ${LOGFILE} 2>&1
				echo -e "!! EXPORT ERROR !!" >> ${LOGFILE} 2>&1
				EMAIL_LOG_FAIL
				exit 1;
			fi
		else
			echo -e "" >> ${LOGFILE} 2>&1
			echo -e "!! PARFILE ERROR !!" >> ${LOGFILE} 2>&1
			EMAIL_LOG_FAIL
			exit 1;
		fi
	else
		echo -e "" >> ${LOGFILE} 2>&1
		echo -e "!! PARFILE ERROR !!" >> ${LOGFILE} 2>&1
		EMAIL_LOG_FAIL
		exit 1;
	fi
else
	echo -e "" >> ${LOGFILE} 2>&1
	echo -e "!! ${INSTANCE} UNREACHABLE !!" >> ${LOGFILE} 2>&1
	EMAIL_LOG_FAIL
	exit 1;
fi