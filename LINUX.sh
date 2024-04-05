# Find specific text in a file
grep "08-FEB" listener.log | awk  '{ if ( $NF != 0 ) print $0 }'


# Find biggest files
du -ah | sort -rh | head -n 30

# Find folder sizes
du -sh ./*/

# Quando o find não consegue remover devido a quantidade de arquivos:
find -type f -name '*.trc' -mtime +1 -print0 | xargs -0 rm -f 
find -type f -name '*.trm' -mtime +1 -print0 | xargs -0 rm -f 

find -type f -name '*.aud' -mtime +1 -print0 | xargs -0 rm -f 

ps aux | grep -i back

# Reexecutar comandos em intervalo
watch "ps aux | sort -nrk 3,3 | head -n 5"

# Find instances in a server:
/bin/ps -ef | grep ora_pmon | grep -v grep

# Check for big files:
du -m *.trc | grep -v 0.00
du -ch ./

# Instalar PV e mostrar barra de progresso no TAR
pv [arquivo].tar.gz | tar -xvzf - -C .
rpm -uVh http://www.ivarch.com/programs/rpms/pv-1.6.6-1.x86_64.rpm