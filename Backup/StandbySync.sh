#set -x
#!/bin/ksh

# Controle de Execucao
if [ -e ${DIR_LOGS}/run_standby_${ORACLE_SID}.control ];
then
	echo >> ${RECOVER_LOG} 2>&1
	echo `date '+%Y%m%d_%H%M'` - Control file exists, execution aborted >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1
else
	touch ${DIR_LOGS}/run_standby_${ORACLE_SID}.control >> ${RECOVER_LOG} 2>&1

# Variaveis Ambiente
	. /etc/ambiente_viasoft_stb.sh

# Variaveis Logs
	export DIR_LOG=${ORACLE_BASE}/scripts/logs
	export RECOVER_LOG=${DIR_LOG}/${ORACLE_SID}/recover_${ORACLE_SID}_`date +%Y%m%d_%H%M`.log

# Variaveis Archives
	export DIR_ARC_PRD=/u01/app/oracle/standby/${ORACLE_SID}
	export DIR_ARC_STB=/u01/app/oracle/standby/${ORACLE_SID}

	echo '===========================================================================================' >> ${RECOVER_LOG} 2>&1
	echo '==========================   I N I C I O   D O   R E C O V E R   ==========================' >> ${RECOVER_LOG} 2>&1
	echo '===========================================================================================' >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1
	date >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1

	echo >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo '=====  COPIA DE ARCHIVES PARA O STANDBY  =====' >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1

	rsync --remove-source-files -tzaP oracle@172.16.17.10:${DIR_ARC_PRD}/* ${DIR_ARC_STB}/

	echo >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo '=  ULTIMOS ARCHIVES COPIADOS PARA O STANDBY  =' >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1

	ls -rt ${DIR_ARC_STB}/*.dbf >> ${RECOVER_LOG} 2>&1

	echo >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo '=============  APLICAR ARCHIVES  =============' >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1

sqlplus / as sysdba >> ${RECOVER_LOG} <<!eof
alter database recover automatic standby database until cancel;
alter database recover cancel;
exit
!eof

	echo >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo '====  ULTIMO ARCHIVE APLICADO NO STANDBY  ====' >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1

	ls -rt ${DIR_ARC_STB}/*.dbf | tail -1 >> ${RECOVER_LOG} 2>&1

	echo >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo '=  REMOCAO DE ARCHIVES APLICADOS NO STANDBY  =' >> ${RECOVER_LOG} 2>&1
	echo '==============================================' >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1

	find ${DIR_ARC_STB}/*.dbf -print -exec \rm -f {} \; >> ${RECOVER_LOG} 2>&1

	find ${DIR_LOG}/${ORACLE_SID}/recover_${ORACLE_SID}_* -mtime +4 -exec \rm -f {} \; > /dev/null 2>&1

	echo >> ${RECOVER_LOG} 2>&1
	echo '===========================================================================================' >> ${RECOVER_LOG} 2>&1
	echo '=============================   F I M   D O   R E C O V E R   =============================' >> ${RECOVER_LOG} 2>&1
	echo '===========================================================================================' >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1
	date >> ${RECOVER_LOG} 2>&1
	echo >> ${RECOVER_LOG} 2>&1
	rm -f ${DIR_LOGS}/run_standby_${ORACLE_SID}.control >> ${RECOVER_LOG} 2>&1
fi