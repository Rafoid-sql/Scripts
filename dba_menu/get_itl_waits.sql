prompt Top 10 object_name with ITL Waits since instance startup...
set lines 250 pages 999
col i for 9
col owner for a20
col object_name for a30
col subobject_name for a30
col tablespace_name for a30
col object_type for a20
select * from 
(
select inst_id i,OWNER,OBJECT_NAME, SUBOBJECT_NAME, TABLESPACE_NAME, 
       OBJECT_TYPE, VALUE
  from gv$segment_statistics 
  where statistic_name = 'ITL waits'
  and value > 0
  and owner not in ('SYS','SYSTEM')
  order by value desc
)
where rownum <= 10
/

prompt object_name with ITL Waits from AWR in last x hours...
set lines 250 pages 999 verify off
col i for 9
col owner for a20
col object_name for a30
col subobject_name for a30
col object_type for a20
select b.instance_number i,a.owner,a.object_name,a.subobject_name,sum(b.itl_waits_delta) itl_waits_delta 
from dba_objects a, sys.wrh$_seg_stat b 
where 
a.object_id=b.obj# 
and a.data_object_id = b.dataobj# 
and itl_waits_delta > 0 
and a.owner not in('SYS','SYSTEM') 
and (dbid,snap_id,instance_number) in 
(
select dbid,max(snap_id),instance_number 
from dba_hist_snapshot 
where begin_interval_time > sysdate-&1/24 
group by dbid,instance_number
) 
group by b.instance_number,a.owner,a.object_name,a.subobject_name
/
