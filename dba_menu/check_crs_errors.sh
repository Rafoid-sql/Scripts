#!/bin/ksh
#######################################################################
# Name:         check_crs_errors.sh
# Function:     To check for errors in crs log files for a particular
#               minute of the day
# Author:       Chandan Acharya
# Version:      1.0 01/26/2021 new script
#######################################################################

if [ `ps -ef | grep crsd.bin | grep -v grep | wc -l` -eq 1 ]
then

gi_ver=`$ORACLE_HOME/bin/crsctl query crs releaseversion | awk '{print $NF}' | awk -F. '{print $1}' | sed 's/\[//g'`
if [ ${gi_ver} -eq 11 ]
then
	echo "Script does not support 11.2 Clusterware version!!!"
	exit
else

ORACLE_SID=grid
ORAENV_ASK=NO
. /usr/local/bin/oraenv > /dev/null 2>&1

cd ${ORACLE_BASE}/diag/crs/`hostname`/crs/trace

printf "\033[1;33mThis script will check for warning|error|failed text in CRS alert.log and trc files for the timestamp entered\033[m\n"

print -n "Enter datetime [YYYY-MM-DD HH24:MI]: "
read input
echo

tstamp="${input}"

printf "\033[1;33mChecking alert.log file...\033[m\n"
cat alert.log | grep "${tstamp}" | egrep -wi 'error|failed'

echo
printf "\033[1;33mChecking all CRS trace files...\033[m\n"

for FILE in `find . -name "*.trc" -exec egrep -l "${tstamp}" {} \;`
do
        if [ `cat $FILE | grep "${tstamp}" | egrep -wic 'warning|error|failed'` -gt 0 ]
        then
                echo $FILE
                cat $FILE | grep "${tstamp}" | egrep -wi 'warning|error|failed'
                echo ------------
        fi
done

fi # gi_ver

else
	echo "Oracle Clusterware is not running!!!"
	exit
fi # ps
