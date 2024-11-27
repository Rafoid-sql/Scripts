#set -x
#!/bin/sh

#ADMIN='ro617589@digicelgroup.com sonneil.wellington@digicelgroup.com Cg001110@digicelgroup.com'
#ADMIN='rafael.oliveira@digicelgroup.com'
ADMIN='r0617589@digicelgroup.com'
DEPLETED=100
CRITICAL=90
#WARNING=80
WARNING=40
EXCLUDE_LIST="/auto/ripper|loop"

main_prog()
        {
                while read -r output;
                do
                        USED=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
                        PART=$(echo "$output" | awk '{print $2}')
                        if [[ $USED -eq $DEPLETED ]]
                        then
                                echo "partition \"$PART ($USED%)\" on server $(hostname), $(date)" | mail -s "FATAL: partition \"$PART ($USED%)\" on $(hostname) is depleted" "$ADMIN"
                        elif [[ $USED -ge $CRITICAL && $USED -lt $DEPLETED ]]
                        then
                                echo "partition \"$PART ($USED%)\" on server $(hostname), $(date)" | mail -s "CRITICAL: partition \"$PART ($USED%)\" on $(hostname) is almost out of disk space" "$ADMIN"
                        elif [[ $USED -ge $WARNING && $USED -lt $CRITICAL ]]
                        then
                                echo "partition \"$PART ($USED%)\" on server $(hostname), $(date)" | mail -s "WARNING: partition \"$PART ($USED%)\" on $(hostname) is filling up" "$ADMIN"
                        fi
                done
        }

if [[ "$EXCLUDE_LIST" != "" ]]
then
        df -H | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
        df -H | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
fi
