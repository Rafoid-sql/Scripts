set lines 250 pages 999 verify off
col date_hr for a40
col LOGINS for a10
col i for 9
select * from
(
select d.name, sn.instance_number i, to_char(sn.begin_interval_time, 'YYYY-MM-DD HH24:MI') starttime,
       to_char(see.value-seb.value) Logins
  from sys.wrh$_stat_name en, sys.wrh$_sysstat seb, sys.wrh$_sysstat see, sys.wrm$_snapshot sn, v$database d
where sn.begin_interval_time > sysdate-&1/24
   and sn.snap_id = see.snap_id
   and sn.dbid    = see.dbid
   and sn.instance_number = see.instance_number
   and seb.snap_id = see.snap_id - 1
   and seb.dbid = see.dbid
   and seb.instance_number = see.instance_number
   and seb.stat_id = see.stat_id
   and see.dbid = en.dbid
   and see.stat_id = en.stat_id
   and en.stat_name = 'user logons cumulative'
order by 1,3,2
)
where Logins > 0
/
