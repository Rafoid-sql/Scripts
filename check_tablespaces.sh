#set -x
#!/bin/sh

SHELL=/bin/sh
USER=oracle
HOME=/home/oracle

#PATH=/bin:/sbin:/usr/bin:/usr/sbin

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/18.0.0/db18c
export ORACLE_SID=TTCDRMSC
export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$ORACLE_HOME/bin:/usr/bin:/bin
export SCR_DIR=/home/oracle/scripts

#ADMIN="ro617589@digicelgroup.com"
ADMIN="COE_DBA@DIGICELGROUP.COM"

LIMIT=90

$ORACLE_HOME/bin/sqlplus "/ as sysdba" <<-EOF
SET FEED OFF
SET LINESIZE 100
SET PAGESIZE 200
COL "TABLESPACE" FOR A30
COL "%FULL" FOR 999.99
spool '$SCR_DIR/tablespace.alert'
SELECT TBM.TABLESPACE_NAME AS "TABLESPACE",
ROUND(TBM.TABLESPACE_SIZE * TB.BLOCK_SIZE/(1024*1024*1024),2) AS "TOTAL(GB)",
ROUND(TBM.USED_SPACE * TB.BLOCK_SIZE/(1024*1024*1024),2) AS "USED(GB)",
ROUND((TBM.TABLESPACE_SIZE-TBM.USED_SPACE) * TB.BLOCK_SIZE/(1024*1024*1024),2) "FREE(GB)",
TBM.USED_PERCENT AS "%FULL"
FROM DBA_TABLESPACE_USAGE_METRICS TBM
JOIN DBA_TABLESPACES TB ON TB.TABLESPACE_NAME = TBM.TABLESPACE_NAME
WHERE TBM.USED_PERCENT >${LIMIT}
ORDER BY "%FULL" ASC;
spool off;
exit
EOF
sed '/^SQL>/d; /^ /d; /^$/d' "$SCR_DIR/tablespace.alert" > $SCR_DIR/tbs.tmp && mv $SCR_DIR/tbs.tmp "$SCR_DIR/tablespace.alert"
rm -f $SCR_DIR/tbs.tmp
if [ `cat $SCR_DIR/tablespace.alert|wc -l` -gt 3 ]
then
        cp $SCR_DIR/tablespace.alert $SCR_DIR/tablespaces.log
        #echo "Tablespaces on $(hostname) are above ${LIMIT}%" | mail -s "WARNING: Tablespaces on $(hostname) are above ${LIMIT}%" "$ADMIN" < tablespaces.log
        mail -s "WARNING: Tablespaces on $(hostname) are above ${LIMIT}%" "$ADMIN" < $SCR_DIR/tablespaces.log
        rm -f $SCR_DIR/tablespaces.log
elif [ `cat $SCR_DIR/tablespace.alert|wc -l` -gt 0 ]
then
        cp $SCR_DIR/tablespace.alert $SCR_DIR/tablespaces.log
        #echo "Tablespace on $(hostname) is above ${LIMIT}%" | mail -s "WARNING: Tablespace on $(hostname) is above ${LIMIT}%" "$ADMIN" < tablespaces.log
        mail -s "WARNING: Tablespace on $(hostname) is above ${LIMIT}%" "$ADMIN" < $SCR_DIR/tablespaces.log
        rm -f $SCR_DIR/tablespaces.log
fi
