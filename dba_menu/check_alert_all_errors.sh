#!/bin/ksh
#################################################################################
# Name:         check_alert_all_errors.sh
# Function:     To check all ORA- errors in alert_SID.log file.
# Author:       Chandan Acharya
# Version:      1.0 03/28/2022 New script
#################################################################################

for SID in $(ps -ef | grep -v grep | grep ora_pmon | cut -d_ -f3-)
do
export ORACLE_SID=$SID
export PATH=/usr/local/bin:$PATH
export ORAENV_ASK=NO
. oraenv        > /dev/null 2>&1

echo "set lines 100 pages 0 feed off trims on
select value from v\$diag_info where name = 'Diag Trace';" | sqlplus -s / as sysdba | read l_alert_dir

alert_log_file=${l_alert_dir}/alert_${ORACLE_SID}.log

echo
printf "\033[1;33mDisplaying all unique ORA- errors in ${alert_log_file} file\033[m\n"
echo

grep ^ORA- ${alert_log_file} | sort -u

done
