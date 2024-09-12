#set -x
#!/bin/sh

ADMIN='rafael.oliveira@digicelgroup.com sonneil.wellington@digicelgroup.com Cg001110@digicelgroup.com'
DEPLETED=100
CRITICAL=90
WARNING=80
EXCLUDE_LIST="/auto/ripper|loop"

main_prog()
	{
		while read -r output;
		do
			USED=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
			PART=$(echo "$output" | awk '{print $2}')
			if [[ $USED -eq $DEPLETED ]]
			then
				echo "usedition \"$PART ($USED%)\" on server $(hostname), $(date)" | \
				mail -s "FATAL: usedition \"$PART ($USED%)\" on $(hostname) is depleted" "$ADMIN"
			elif [[ $USED -ge $CRITICAL && $USED -lt $DEPLETED ]]
			then
				echo "usedition \"$PART ($USED%)\" on server $(hostname), $(date)" | \
				mail -s "CRITICAL: usedition \"$PART ($USED%)\" on $(hostname) is almost out of disk space" "$ADMIN"
			elif [[ $USED -ge $WARNING && $USED -lt $CRITICAL ]]
			then
				echo "usedition \"$PART ($USED%)\" on server $(hostname), $(date)" | \
				mail -s "WARNING: usedition \"$PART ($USED%)\" on $(hostname) is filling up" "$ADMIN"
			fi
		done
	}

if [[ "$EXCLUDE_LIST" != "" ]]
then
	df -H | grep -vE "^Filesystem|tmpfs|cdrom|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
	df -H | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5 " " $6}' | main_prog
fi
