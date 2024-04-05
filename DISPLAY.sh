#ROOT
xauth list | grep unix`echo $DISPLAY | cut -c10-12` > /tmp/xauth<hostname>

#ORACLE
touch /home/oracle/.Xauthority
xauth add `cat /tmp/xauth<hostname>`