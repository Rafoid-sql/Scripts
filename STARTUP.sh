#!/bin/bash

export TMP=/tmp
export TMPDIR=$TMP
export PATH=/usr/sbin:/usr/local/bin:$PATH
export ORACLE_HOSTNAME=ORAPRD


# Start Listener
lsnrctl start


# Start SAG
export ORACLE_SID=sag
ORAENV_ASK=NO
. oraenv
ORAENV_ASK=YES

sqlplus / as sysdba << EOF
STARTUP;
EXIT;
EOF


# Start DANIELI
export ORACLE_SID=danieli
ORAENV_ASK=NO
. oraenv
ORAENV_ASK=YES

sqlplus / as sysdba << EOF
STARTUP;
EXIT;
EOF


# Start QUALITOR
export ORACLE_SID=qualitor
ORAENV_ASK=NO
. oraenv
ORAENV_ASK=YES

sqlplus / as sysdba << EOF
STARTUP;
EXIT;
EOF

# Start DOMIT
export ORACLE_SID=domit
ORAENV_ASK=NO
. oraenv
ORAENV_ASK=YES

sqlplus / as sysdba << EOF
STARTUP;
EXIT;
EOF