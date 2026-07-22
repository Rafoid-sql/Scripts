set lines 250 pages 999 verify off long 65536 longc 65536
select sql_text
from dba_hist_sqltext
where sql_id ='&1'
/
