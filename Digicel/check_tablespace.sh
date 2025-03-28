#set -x
#!/bin/sh

#ADMIN="rafael.oliveira@digicelgroup.com"
ADMIN="'coe_dba@digicelgroup.com 'alessandro.guasone@digicelgroup.com' 'pardeep.kumar@digicelgroup.com'"
PATH=/sbin:$PATH
HOST=`hostname | tr a-z A-Z`
OS_TYPE=$(uname)
TBS_TMP="/scripts/logs/tbs_${HOST}.tmp"
TBS_LOG="/scripts/logs/${HOST}_tablespace_usage.log"
TBS_ALERT="/scripts/logs/tablespace_${HOST}.alert"
ORAENV_ASK=NO
LIMIT=$1
EXCLUDE_TB="'UNDO'"

. oraenv

GET_MAIN_IP()
{
        case "$OS_TYPE" in
                Linux)
                        /usr/sbin/ip route get 1.1.1.1 | /usr/bin/awk '/src/ {print $7}' | /usr/bin/head -n 1
                        ;;
                AIX)
                        /usr/sbin/ifconfig -a | /usr/bin/awk '/inet / && !/127.0.0.1/ {print $2; exit}'
                        ;;
                HP-UX)
                        /usr/sbin/netstat -in | /usr/bin/awk '/^[^ ]/ && !/127.0.0.1/ {print $4; exit}'
                        ;;
                SunOS)
                        /sbin/ifconfig -a | /usr/bin/awk '/inet / && !/127.0.0.1/ {print $2; exit}'
                        ;;
                *)
                        exit 1
                        ;;
        esac
}
MAIN_IP=$(GET_MAIN_IP)

$ORACLE_HOME/bin/sqlplus "/ as sysdba" <<-EOF
SET FEEDBACK OFF
SET LINESIZE 120
SET PAGESIZE 9999
SET TRIMSPOOL ON
COL "TABLESPACE" FOR A30
COL TOTAL(GB) FOR 999,999,999.99
COL USED(GB) FOR 999,999,999,999.99
COL FREE(GB) FOR 999,999,999.99
COL "%FULL" FOR 999.99
spool '$TBS_ALERT'
SELECT TOTAL.TS TABLESPACE, DECODE(TOTAL.MB, NULL, 'OFFLINE', DBAT.STATUS) STATUS, TOTAL.MB TOTAL_MB, NVL(TOTAL.MB - FREE.MB, TOTAL.MB) USED_MB, NVL(FREE.MB, 0) FREE_MB, DECODE(TOTAL.MB, NULL, 0, NVL(ROUND((TOTAL.MB - FREE.MB) / (TOTAL.MB) * 100, 2), 100)) PCT_USED
FROM (SELECT TABLESPACE_NAME TS, SUM(BYTES) / 1024 / 1024 MB FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) TOTAL
LEFT JOIN (SELECT TABLESPACE_NAME TS, SUM(BYTES) / 1024 / 1024 MB FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) FREE
ON TOTAL.TS = FREE.TS
JOIN DBA_TABLESPACES DBAT
ON TOTAL.TS = DBAT.TABLESPACE_NAME
WHERE TOTAL.TS NOT IN (${EXCLUDE_TB})
AND DECODE(TOTAL.MB, NULL, 0, NVL(ROUND((TOTAL.MB - FREE.MB) / (TOTAL.MB) * 100, 2), 100)) > ${LIMIT}
ORDER BY 6;
spool off;
exit
EOF

sed '/^SQL>/d; /^ /d; /^$/d' "$TBS_ALERT" > $TBS_TMP && mv $TBS_TMP "$TBS_ALERT"

if [ "$(wc -l < "$TBS_ALERT")" -gt 2 ]; then
    mv "$TBS_ALERT" "$TBS_LOG"
    echo -e "Instance: $ORACLE_SID\nIP Address: $MAIN_IP\n\nPlease find the tablespace log attached." | mail -s "Tablespace Alert on $HOST" -a $TBS_LOG "$ADMIN"
fi

rm -f $TBS_TMP
