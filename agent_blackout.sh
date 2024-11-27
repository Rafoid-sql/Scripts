#!/bin/ksh
#################################################################################
# Name:         start_blackout_agent_indefinite.sh
# Function:     To enable indefinite period blackout at agent level
# Author:       Hiten Mehta
# Version:      1.0 11/19/2021 New script
#################################################################################


case `uname` in
  AIX)
orafileloc=/etc
        ;;
  HP-UX)
orafileloc=/var/opt/oracle
        ;;
  SunOS)
orafileloc=/var/opt/oracle
        ;;
  Linux)
orafileloc=/etc
        ;;
esac

if [ -s ${orafileloc}/oragchomelist ]; then
        export AGENT_HOME=`cat ${orafileloc}/oragchomelist | grep agent | awk -F: '{print $1}'`
else
        echo "FAILED: Please check if EM Agent is installed on host..."
        exit
fi

export BLACKOUT_NAME=`hostname`_indefinite
date | tee /tmp/emagent_start_blackout_indefinite.log
cd $AGENT_HOME/bin
./emctl start blackout $BLACKOUT_NAME -nodeLevel | tee -a /tmp/emagent_start_blackout_indefinite.log




#!/bin/ksh
#################################################################################
# Name:         start_blackout_agent.sh
# Function:     To enable blackout at agent level
# Author:       Chandan Acharya
# Version:      1.0 3/18/2018 New script
#               1.1 8/21/2020 Added error handling
#################################################################################

if [ $# -ne 1 ]
then
   echo
   echo "USAGE:" `basename $0` [time_in_mins]
   exit
fi

export mins=$1

case `uname` in
  AIX)
orafileloc=/etc
        ;;
  HP-UX)
orafileloc=/var/opt/oracle
        ;;
  SunOS)
orafileloc=/var/opt/oracle
        ;;
  Linux)
orafileloc=/etc
        ;;
esac

if [ -s ${orafileloc}/oragchomelist ]; then
        export AGENT_HOME=`cat ${orafileloc}/oragchomelist | grep agent | awk -F: '{print $1}'`
else
        echo "FAILED: Please check if EM Agent is installed on host..."
        exit
fi

export BLACKOUT_NAME=`hostname`_maintenance
date | tee /tmp/emagent_start_blackout.log
cd $AGENT_HOME/bin
./emctl start blackout $BLACKOUT_NAME -nodeLevel -d $mins | tee -a /tmp/emagent_start_blackout.log
