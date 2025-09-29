/*

HOST rm h.sql 
HOST vi h.sql 



*/


set termout off
set markup HTML ON HEAD " -
 -
" -
BODY "" -
TABLE "border='1' align='center' summary='Script output'" -
SPOOL ON ENTMAP ON PREFORMAT OFF


col sdate new_value sysdt
select to_char(sysdate,'_YYYY-MON-DD_HH24.MI.SS.') sdate from dual;
col INSTANCE_NAME new_value instname
set pages 5000
select INSTANCE_NAME from v$instance;
spool HTMLOutput_&instname&sysdt.html



--***************
--QUERY GOES HERE
--***************

SELECT * FROM ALL_TABLES WHERE owner = 'DLS_PTSCS1';

--***************
--QUERY ENDS HERE
--***************


spool off;
set markup html off spool off;
set termout on  ;
exit;