#!/bin/ksh
#################################################################################
# Name:         check_alert_log.sh
# Function:     To check last x lines in alert_SID.log file.
# Author:       Chandan Acharya
# Version:      1.0 09/06/2020  New script
#################################################################################
if [ $# -ne 1 ]
then
   echo
   printf "\033[1;31mUSAGE: `basename $0` [num_of_lines]\033[m\n"
   exit
fi

lines=$1

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
printf "\033[1;33mDisplaying last ${lines} of ${alert_log_file} file\033[m\n"
echo

tail -${lines} ${alert_log_file}

done
