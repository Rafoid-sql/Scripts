#!/bin/ksh
#########################################################################################
#
# Script to start scp in n Threads
#
# Build by Spag
# Version 1.0 - 05/11/2014
#
# Obs: SSH Keys must be exchanged for this script to work.
#
#########################################################################################
#set -x
SCRIPT_NAME=copy_scp.sh
if [ $# -lt 1 ]
then
  echo "Usage: $SCRIPT_NAME work_folder part_filename number_threads target_server remote_folder"
  echo "Example: $SCRIPT_NAME /oracle/g01/bkup03/TEOCOP/temp dmp 2 plsaa240z /oracle/g01/bkup01/transfer/"
  exit
fi
BASEDIR=$(dirname $0)
# Gets a random number to create the files
RNDN=`dd if=/dev/urandom count=1 2> /dev/null | cksum | cut -f1 -d" "`
wfolder=$1
wfilet=$2
wproc=$3
remote_server=$4
remote_folder=$5
psleep=5
sflist=/tmp/sflist_$RNDN.lst
tplist=/tmp/tplist_$RNDN.lst
srlist=/tmp/srlist_$RNDN.run
erlist=/tmp/erlist_$RNDN.err
drlist=/tmp/drlist_$RNDN.don
fscp() {
#set -x
srlist=$3
wfile=`echo $1 | awk -F"/" '{print $NF}'`
wpath=$2
if [ -d $wpath/$wfile ]
   then
      echo $wfile "is a directory"
   else
      echo $1.running >> $srlist
      nohup scp $1 $remote_server:$remote_folder > /tmp/nohup.out 2>&1 &
      P1=$!
      wait $P1
      if [ $? -eq 0 ]
         then
           echo ${wfile} >> $drlist
         else
           echo ${wfile} >> $erlist
      fi
fi
}
resetlst() {
echo > $sflist
echo > $tplist
echo > $srlist
echo > $erlist
echo > $drlist
}
makelist() {
#set -x
if [ "${wfilet}" = "ALL" ]
   then
      ls -la $wfolder/* > /dev/null
   else
      ls -la $wfolder/*$wfilet* > /dev/null
fi
lerro=$?
if [ $lerro -eq 2 ]
   then
      echo "No Files Found"
      exit 2
   else
      if [ "${wfilet}" = "ALL" ]
         then
             ls -la $wfolder/* | awk '{print $9}' > $sflist
         else
             ls -la $wfolder/*$wfilet* | awk '{print $9}' > $sflist
      fi
fi
}
runscp() {
#set -x
tcount=0
while [ ${tcount} -lt $1 ]; do
   work_on=`head -1 $sflist`
   fscp $work_on $wfolder $srlist $remote_server $remote_folder &
   sed '1d' $sflist > $tplist
   cat $tplist > $sflist
   tcount=$(( $tcount + 1 ))
done
}
checkerror() {
errornum=`cat $erlist | wc -l`
if [ ${errornum} -gt 0 ]; then
      cat $erlist
	  rm $sflist
	  rm $tplist
	  rm $srlist
	  rm $drlist
   else
      rm $sflist
	  rm $tplist
	  rm $srlist
	  rm $erlist
	  rm $drlist
fi
}
checkrun() {
#set -x
DT=`date +%H:%M`
lcount=`cat $sflist | wc -l`
if [ $lcount -eq 0 ]
then
   rcount=`cat $srlist | grep -i running | wc -l`
   if [ $rcount -ne 0 ]
   then
    if [ ${endpcnt} -eq 12 ]
	then
      echo "${DT} Running count is : " $rcount
	  export endpcnt=0
	fi
	endpcnt=$(($endpcnt + 1))
   else
      date
	  checkerror
      exit 0
   fi
else
   rcount=`cat $srlist | grep -i running | wc -l`
   if [ $rcount -lt $wproc ]
      then
         $1 `expr $wproc - $rcount`
         echo "${DT} Running count is : " $rcount "Starting : " `expr $wproc - $rcount`
		 export dispcnt=0
      else
	     if [ ${dispcnt} -eq 60 ]
		 then
         echo "${DT} Running count is : " $rcount "No process started."
		 export dispcnt=0
		 fi
		 dispcnt=$(($dispcnt + 1))
   fi
fi
}
update_lists() {
for i in `cat $erlist`; do
   perl -p -i -e s/$i.running/$i.error/g ${srlist}
done
for i in `cat $drlist`; do
   perl -p -i -e s/$i.running/$i.done/g ${srlist}
done
}
date
resetlst
makelist
#runscp $wproc
export dispcnt=0
export endpcnt=0
while true
do
update_lists
checkrun runscp
sleep $psleep
done