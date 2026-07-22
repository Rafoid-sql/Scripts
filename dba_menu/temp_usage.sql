set lines 300 pages 999
col id for 9
col "User" for a25 word_wrapped
col "Program" for a30 word_wrapped
col "Module" for a30 word_wrapped
col "Tablespace" for a15 word_wrapped
col "SQL TEXT" for a100 word_wrapped
SELECT distinct s.inst_id id,s.sid "SID",s.username "User",s.program "Program", 
--s.module "Module",
u.tablespace "Tablespace",
u.contents "Contents", u.segtype,u.extents "Extents", u.blocks*8/1024 "Used Space(MB)", s.sql_id
--,q.sql_text "SQL TEXT"
--,a.object "Object", k.bytes/1024/1024 "Temp File Size"
FROM gv$session s, gv$sort_usage u,gv$sql q --,v$access a, dba_temp_files k
WHERE s.inst_id =u.inst_id
and s.inst_id =q.inst_id
and s.saddr=u.session_addr
and s.sql_address=q.address
/
--and s.SQL_ID(+)=u.SQL_ID
--and s.sql_id='1cgsqfbzby9mm'
--and s.username='OPS$ORACLE';
--and u.tablespace=k.tablespace_name;

