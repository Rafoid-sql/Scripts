#set -x
#!/bin/sh

ASM_INSTANCE=$(ps -ef | grep -E "asm_pmon_\+ASM([0-9]*)?" | wc -l)
if [[ $ASM_INSTANCE -eq 0 ]]; then
    exit 1
fi

#ADMIN="rafael.oliveira@digicelgroup.com"
ADMIN="'coe_dba@digicelgroup.com 'alessandro.guasone@digicelgroup.com' 'pardeep.kumar@digicelgroup.com'"
OS_TYPE=$(uname)
HOST=$(hostname | tr a-z A-Z)
LOGFILE="/scripts/logs/${HOST}_asm_usage.log"
SQLFILE="/scripts/logs/${HOST}_RETVAL.log"
ORAENV_ASK=NO
EXCLUDE_DG="'TEMP1','CTFILE1','CTFILE2'"
LIMIT=85

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

> "$LOGFILE"

${ORACLE_HOME}/bin/sqlplus "/ as sysdba" <<- EOF
    SET LINESIZE 140 PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF VERIFY OFF TERM OFF TRIMOUT ON TRIMSPOOL ON TIMING OFF
    spool '$SQLFILE'
    COL GROUP_NUMBER FORMAT 999
    COL DISKGROUP FORMAT A20
    COL TOTAL_MB FORMAT 999999999
    COL FREE_MB FORMAT 999999999
    COL TOT_USED FORMAT 999999999
    COL PCT_USED FORMAT 999
    COL PCT_FREE FORMAT 999
    SELECT GROUP_NUMBER,NAME DISKGROUP,TOTAL_MB,FREE_MB,TOTAL_MB-FREE_MB TOT_USED,PCT_USED,PCT_FREE
    FROM (
        SELECT GROUP_NUMBER,NAME,TOTAL_MB,FREE_MB,ROUND(((TOTAL_MB-NVL(FREE_MB,0))/DECODE(TOTAL_MB,0,1,TOTAL_MB))*100) PCT_USED,ROUND((FREE_MB/TOTAL_MB)*100) PCT_FREE
        FROM V\$ASM_DISKGROUP
        WHERE TOTAL_MB > 0 AND NAME NOT IN (${EXCLUDE_DG})
        ORDER BY PCT_FREE
    );
    spool off;
EOF

while read -r values; do
    USED_PCT=$(echo "$values" | awk '{print $6}')
    DG_NAME=$(echo "$values" | awk '{print $2}')
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ ${USED_PCT} -ge ${LIMIT} ]]; then
        echo "[$TIMESTAMP] Diskgroup $DG_NAME has used $USED_PCT% of its available space." >> "$LOGFILE"
    fi
done < "$SQLFILE"

if [[ -s "$LOGFILE" ]]; then
        {
                cat "$LOGFILE"
                echo -e "\n\nInstance: $ORACLE_SID"
                echo -e "IP Address: $MAIN_IP"
        } | mail -s "ASM Alert on $HOST" "$ADMIN" < "$LOGFILE"
fi

rm -f "$SQLFILE"
