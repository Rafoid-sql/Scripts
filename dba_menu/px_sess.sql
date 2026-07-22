set lines 250 pages 999
col "Username" for a30
col "QC/Slave" for a20
col "SlaveSet" for a10
col "SID" for a10
col "Slave INST" for a5
col "QC SID" for a10
col "QC INST" for a5
select
decode(px.qcinst_id,NULL,username,' - '||lower(substr(pp.server_name,length(pp.server_name)-4,4) ) )"Username",
decode(px.qcinst_id,NULL, 'QC', '(Slave)') "QC/Slave" ,to_char( px.server_set) "SlaveSet",
to_char(s.sid) "SID",
s.sql_id,
to_char(px.inst_id) "Slave INST",
decode(px.qcinst_id, NULL ,to_char(s.sid) ,px.qcsid) "QC SID",
to_char(px.qcinst_id) "QC INST",
px.req_degree "Req. DOP",
px.degree "Actual DOP"
from 
gv$px_session px,
gv$session s ,
gv$px_process pp
where px.sid=s.sid (+)
and px.serial#=s.serial#(+)
and px.inst_id = s.inst_id(+)
and px.sid = pp.sid (+)
and px.serial#=pp.serial#(+)
order by 6 , 1 desc
/
