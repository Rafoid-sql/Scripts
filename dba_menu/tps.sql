set lines 250 pages 999
prompt max tps from previous day...
select instance_name,round(max(statvalue)) max_tps_prev_day
from 
(
select i.instance_name,sn.begin_interval_time,round(sum(see.value-seb.value)/900) StatValue
  from sys.wrh$_stat_name en, sys.wrh$_sysstat seb, sys.wrh$_sysstat see, sys.wrm$_snapshot sn, gv$instance i
 where sn.begin_interval_time between trunc(sysdate)-1  and trunc(sysdate)
   and sn.snap_id = see.snap_id
   and sn.dbid    = see.dbid
   and sn.instance_number = see.instance_number
   and seb.snap_id = see.snap_id - 1
   and seb.dbid = see.dbid
   and seb.instance_number = see.instance_number
   and seb.stat_id = see.stat_id
   and see.dbid = en.dbid
   and see.stat_id = en.stat_id
   and en.stat_name in ('user commits','user rollbacks')
   and sn.instance_number = i.inst_id
 group by i.instance_name,sn.begin_interval_time
)
group by instance_name
order by instance_name
/

prompt max tps hourly(all instances) in last 24 hrs...

col TXNDate for a10
col TXNHour for a7
select to_char(begin_interval_time,'YYYY-MM-DD') TXNDate, to_char(begin_interval_time,'HH24') TXNHour,max(StatValue) tps
from
(
select to_date(to_char(begin_interval_time,'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS') begin_interval_time,sum(StatValue) StatValue
from
(
select sn.begin_interval_time,round(sum(see.value-seb.value)/900) StatValue
  from sys.wrh$_stat_name en, sys.wrh$_sysstat seb, sys.wrh$_sysstat see, sys.wrm$_snapshot sn, gv$instance i
 where sn.begin_interval_time > sysdate-1
   and sn.snap_id = see.snap_id
   and sn.dbid    = see.dbid
   and sn.instance_number = see.instance_number
   and seb.snap_id = see.snap_id - 1
   and seb.dbid = see.dbid
   and seb.instance_number = see.instance_number
   and seb.stat_id = see.stat_id
   and see.dbid = en.dbid
   and see.stat_id = en.stat_id
   and en.stat_name in ('user commits','user rollbacks')
   and sn.instance_number = i.inst_id
 group by sn.begin_interval_time
)
group by to_date(to_char(begin_interval_time,'YYYY-MM-DD HH24:MI:SS'),'YYYY-MM-DD HH24:MI:SS')
order by 1,2
)
group by to_char(begin_interval_time,'YYYY-MM-DD'), to_char(begin_interval_time,'HH24')
order by 1,2
/
