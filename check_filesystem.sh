#!/bin/sh

#ADMIN='rafael.oliveira@digicelgroup.com'
ADMIN='COE_DBA@DIGICELGROUP.COM'
DEPLETED=100
CRITICAL=90
WARNING=70
EXCLUDE_LIST="/auto/ripper|loop|tmpfs|cdrom"
MAIN_DIR="/home/oracle/scripts"
LOGFILE="$MAIN_DIR/disk_usage.log"
HOST=`hostname | tr a-z A-Z`

> "$LOGFILE"

main_prog()
{
    while read -r output; do
        USED=$(echo "$output" | awk '{ print $1 }' | cut -d'%' -f1)
        PART=$(echo "$output" | awk '{ print $2 }')
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

        if [[ $USED -eq $DEPLETED ]]; then
            echo "[$TIMESTAMP] Partition \"$PART\" ($USED%) is depleted." >> "$LOGFILE"
        elif [[ $USED -ge $CRITICAL && $USED -lt $DEPLETED ]]; then
            echo "[$TIMESTAMP] Partition \"$PART\" ($USED%) is almost full." >> "$LOGFILE"
        elif [[ $USED -ge $WARNING && $USED -lt $CRITICAL ]]; then
            echo "[$TIMESTAMP] Partition \"$PART\" ($USED%) is filling up." >> "$LOGFILE"
        fi
    done
}

if [[ "$EXCLUDE_LIST" != "" ]]; then
    df -H | grep -vE "^Filesystem|${EXCLUDE_LIST}" | awk '{ print $5 " " $6 }' | main_prog
else
    df -H | grep -vE "^Filesystem" | awk '{ print $5 " " $6 }' | main_prog
fi

if [[ -s "$LOGFILE" ]]; then
    sort -n -r -k1,1 "$LOGFILE" -o "$LOGFILE"
    mail -s "Disk Usage Alert on $HOST" "$ADMIN" < "$LOGFILE"
fi
