#set -x
#!/bin/sh

#ADMIN="rafael.oliveira@digicelgroup.com"
ADMIN="'coe_dba@digicelgroup.com 'alessandro.guasone@digicelgroup.com' 'pardeep.kumar@digicelgroup.com'"
PATH=/sbin:$PATH
HOST=$(hostname | tr a-z A-Z)
OS_TYPE=$(uname)
LOGFILE="/scripts/logs/${HOST}_dataguard_lag.log"
ORAENV_ASK=NO
LIMIT=10

. oraenv

GET_MAIN_IP() {
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

$ORACLE_HOME/bin/sqlplus "/ as sysdba" <<-EOF > "$LOGFILE"
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT 'APPLY_LAG:' || VALUE || ' ARCHIVES_TO_APPLY:' || ARCHIVES_TO_APPLY
FROM (
  SELECT
    TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS CHECK_TIME,
    (SELECT VALUE FROM V\$DATAGUARD_STATS WHERE NAME = 'apply lag') AS VALUE,
    (SELECT COUNT(*) FROM V\$ARCHIVED_LOG WHERE APPLIED = 'NO') AS ARCHIVES_TO_APPLY
  FROM DUAL
);
EXIT;
EOF

sed -i 's/.*APPLY_LAG/APPLY_LAG/' "$LOGFILE" && sed -i -n '/APPLY_LAG/p' "$LOGFILE"

if grep -q "APPLY_LAG:" "$LOGFILE"; then
  APPLY_LAG=$(grep "APPLY_LAG:" "$LOGFILE" | awk -F'APPLY_LAG:' '{print $2}' | awk '{print $1}' | xargs)
  ARCHIVES_TO_APPLY=$(grep "ARCHIVES_TO_APPLY:" "$LOGFILE" | awk -F'ARCHIVES_TO_APPLY:' '{print $2}' | xargs)
  APPLY_LAG_MIN=$(echo "$APPLY_LAG" | awk -F':' '{print $1 * 60 + $2}')

  if (( APPLY_LAG_MIN >= LIMIT )); then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Apply Lag: $APPLY_LAG Minutes, Archives to Apply: $ARCHIVES_TO_APPLY" >> "$LOGFILE"
  {
    cat "$LOGFILE"
    echo -e "\n\nInstance: $ORACLE_SID"
    echo -e "IP Address: $MAIN_IP"
  } | mail -s "Data Guard Apply Lag on $HOST" "$ADMIN"
  fi
fi

