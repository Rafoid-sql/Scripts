#!/bin/ksh

script_name=$1
logfile=/tmp/email_output.log
host=`hostname`
TO_EMAIL=TEQDatabaseEngineering-Oracle-Prod@T-Mobile.com

> ${logfile}

SEND_MAIL()
{
        SUBJECT="Oracle Scripts Menu Output - ${script_name}"
        BODY_FILE="$2"
        FROM_EMAIL="oracle@${host}"
        TO_EMAIL=$TO_EMAIL

        if [ -z $BODY_FILE ]
        then
                BODY="echo $SUBJECT"
        elif [[ ( ! -z $BODY_FILE ) && ( -f $BODY_FILE ) ]]
        then
                BODY="cat $BODY_FILE"
        else
                BODY="echo $SUBJECT"
        fi

     (
        echo "From: $FROM_EMAIL"
        echo "To: $TO_EMAIL"
        echo "MIME-Version: 1.0"
        echo "Subject: $SUBJECT"
        echo "Content-Type: text/html; charset=us-ascii"
        echo "Content-Transfer-Encoding: 7bit"
        $BODY
      ) | /usr/sbin/sendmail -t -f "$FROM_EMAIL"
}

sqlplus -s /<<EOF
set markup HTML on spool on
spool ${logfile}

SET MARKUP HTML ON SPOOL ON PREFORMAT OFF ENTMAP ON -
HEAD "<TITLE>Report</TITLE> -
<STYLE type='text/css'> -
<!-- BODY {background: #FFFFC6} --> -
</STYLE>" -
BODY "TEXT='#FF00Ff'" -
TABLE "WIDTH='90%' BORDER='5'"
set feedback on echo on verify off termout off pages 9999
@${script_name}
set markup html off
spool off
exit
EOF

LC=`cat $logfile | wc -l`
if [ $LC -eq 10 ]
then
        echo "No html results, do not send email" > /tmp/no_html_results.log
        exit
else
        SEND_MAIL "$SUBJECT" "$logfile"
fi
