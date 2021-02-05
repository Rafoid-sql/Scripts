#set -x
#!/bin/sh

. /etc/ambiente_viasoft.sh

export DIR_RES=/u01/app/oracle/standby/viasoft

echo ""
read -p "## Ultima sequencia aplicada no standby: " SEQ_STB
echo ""

echo ""
echo "## Iniciando restore dos archives no diretorio ${DIR_RES} :"
echo ""

rman target / <<eof
run {
set archivelog destination to '${DIR_RES}';
restore archivelog from sequence ${SEQ_STB};
}
exit
eof

echo ""
echo "## Archives restaurados :"
echo ""
ls -rt ${DIR_RES}/*