#!/bin/sh

#ADMIN="rafael.oliveira@digicelgroup.com"
ADMIN="'coe_dba@digicelgroup.com 'alessandro.guasone@digicelgroup.com' 'pardeep.kumar@digicelgroup.com'"
OS_TYPE=$(uname)
HOST=$(hostname | tr a-z A-Z)
LOGFILE="/scripts/logs/${HOST}_disk_usage.log"
LIMIT=85

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

case "$OS_TYPE" in
        Linux)
                MAIN_IP=$(GET_MAIN_IP)
                DF_CMD="df -H"
                EXCLUDE_LIST="/auto/ripper|loop|tmpfs|cdrom"
                ;;
        HP-UX)
                MAIN_IP=$(GET_MAIN_IP)
                DF_CMD="bdf"
                EXCLUDE_LIST="/tmp|/dev|/proc"
                ;;
        AIX)
                MAIN_IP=$(GET_MAIN_IP)
                DF_CMD="df -k"
                EXCLUDE_LIST="/proc|/tmp|/dev"
                ;;
        SunOS)
                MAIN_IP=$(GET_MAIN_IP)
                DF_CMD="df -k"
                EXCLUDE_LIST="/tmp|/proc"
                ;;
        *)
                exit 1
                ;;
esac

> "$LOGFILE"

main_prog()
{
    while read -r output; do
        USED=$(echo "$output" | awk '{ print $1 }' | cut -d'%' -f1)
        PART=$(echo "$output" | awk '{ print $2 }')
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        if [[ $USED -ge $LIMIT ]]; then
            echo "[$TIMESTAMP] Partition \"$PART\" has used $USED% of its available space." >> "$LOGFILE"
        fi
    done
}

if [[ "$EXCLUDE_LIST" != "" ]]; then
    $DF_CMD | grep -vE "^Filesystem|${EXCLUDE_LIST}" | awk '{ print $5 " " $NF }' | main_prog
else
    $DF_CMD | grep -vE "^Filesystem" | awk '{ print $5 " " $NF }' | main_prog
fi

if [[ -s "$LOGFILE" ]]; then
    sort -n -r -k1,1 "$LOGFILE" -o "$LOGFILE"
        {
                cat "$LOGFILE"
                echo -e "\n\nInstance: $ORACLE_SID"
                echo -e "IP Address: $MAIN_IP"
        } | mail -s "Disk Usage Alert on $HOST" "$ADMIN" < "$LOGFILE"
fi

