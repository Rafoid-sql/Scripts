# set -x
#!/bin/sh
#################################################################################
# Name:         start_blackout_agent_indefinite.sh
# Function:     To enable indefinite period blackout at agent level
#################################################################################


oragchomelist: agent home path (.../agent_13.xxx):agent_inst path

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


export BLACKOUT_NAME=`hostname`_indefinite
date | tee /tmp/emagent_start_blackout_indefinite.log
cd $AGENT_HOME/bin
./emctl start blackout $BLACKOUT_NAME -nodeLevel | tee -a /tmp/emagent_start_blackout_indefinite.log