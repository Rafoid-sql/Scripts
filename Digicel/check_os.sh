#set -x
#!/bin/sh

#ADMIN="rafael.oliveira@digicelgroup.com"
ADMIN="'coe_dba@digicelgroup.com 'alessandro.guasone@digicelgroup.com' 'pardeep.kumar@digicelgroup.com'"
OS_TYPE=$(uname)
HOST=$(hostname | tr a-z A-Z)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOGFILE="/scripts/logs/${HOST}_os_usage.log"
LIMIT_CPU=90
LIMIT_MEMORY=90
LIMIT_SWAP=50

> "$LOGFILE"

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

monitor_system()
{
    case "$OS_TYPE" in
    Linux)
        MAIN_IP=$(GET_MAIN_IP)
        CPU_UTIL=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | awk '{printf "%.0f", $1}')
        MEMORY_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
        MEMORY_USED=$(free -m | awk '/^Mem:/{print $3}')
        SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
        SWAP_USED=$(free -m | awk '/^Swap:/{print $3}')
        ;;
    AIX)
        MAIN_IP=$(GET_MAIN_IP)
        CPU_UTIL=$(vmstat 1 2 | tail -1 | awk '{print 100 - $17}')
        MEMORY_TOTAL=$(svmon -G | awk '/memory/{print $2}')
        MEMORY_USED=$(svmon -G | awk '/memory/{print $3}')
        SWAP_TOTAL=$(lsps -s | grep MB | awk '{print $1}' | sed 's/MB//')
        SWAP_USED=$(lsps -s | grep MB | awk '{print $2}' | sed 's/MB//')
        ;;
    HP-UX)
        MAIN_IP=$(GET_MAIN_IP)
        CPU_UTIL=$(sar 1 1 | grep Average | awk '{print 100 - $5}')
        MEMORY_TOTAL=$(swapinfo -tm | grep memory | awk '{print $2}')
        MEMORY_USED=$(swapinfo -tm | grep memory | awk '{print $3}')
        SWAP_TOTAL=$(swapinfo -tm | grep dev | awk '{print $2}')
        SWAP_USED=$(swapinfo -tm | grep dev | awk '{print $3}')
        ;;
    SunOS | Unix)
        MAIN_IP=$(GET_MAIN_IP)
        CPU_UTIL=$(vmstat 1 2 | tail -1 | awk '{print 100 - $16}')
        MEMORY_TOTAL=$(prtconf | grep Memory | awk '{print $3}')
        MEMORY_USED=$(echo "$MEMORY_TOTAL $(vmstat | tail -1 | awk '{print $5}')" | awk '{print $1 - $2}')
        SWAP_TOTAL=$(swap -s | awk '{print $9}' | sed 's/k//')
        SWAP_USED=$(swap -s | awk '{print $5}' | sed 's/k//')
        ;;
    *)
        exit1
        ;;
    esac

    MEMORY_UTIL=$(echo "$MEMORY_USED $MEMORY_TOTAL" | awk '{printf "%.0f", ($1 / $2) * 100}')

    if [[ $SWAP_TOTAL -gt 0 ]]; then
        SWAP_UTIL=$(echo "$SWAP_USED $SWAP_TOTAL" | awk '{printf "%.0f", ($1 / $2) * 100}')
        if [[ $SWAP_UTIL -ge $LIMIT_SWAP ]]; then
            echo "[$TIMESTAMP] Swap usage is at $SWAP_UTIL% ($SWAP_USED MB used of $SWAP_TOTAL MB)" >> "$LOGFILE"
        fi
    fi

    if [[ $CPU_UTIL -ge $LIMIT_CPU ]]; then
        echo "[$TIMESTAMP] CPU utilization is at $CPU_UTIL%" >> "$LOGFILE"
    fi

    if [[ $MEMORY_UTIL -ge $LIMIT_MEMORY ]]; then
        echo "[$TIMESTAMP] Memory usage is at $MEMORY_UTIL% ($MEMORY_USED MB used of $MEMORY_TOTAL MB)" >> "$LOGFILE"
    fi
}

monitor_system

if [[ -s "$LOGFILE" ]]; then
        {
                cat "$LOGFILE"
                echo -e "\n\nInstance: $ORACLE_SID"
                echo -e "IP Address: $MAIN_IP"
        } | mail -s "System Resource Alert on $HOST" "$ADMIN"
fi
