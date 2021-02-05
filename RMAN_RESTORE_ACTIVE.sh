#set -x
#!/bin/bash

. /etc/ambiente_teste.sh

sqlplus / as sysdba <<EOF
shutdown immediate;
startup nomount;
exit
EOF

rman target sys/alsksys123#@totvs auxiliary / <<EOF
duplicate target database to TESTE;
exit
EOF
