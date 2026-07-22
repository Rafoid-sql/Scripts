set lines 250 pages 999 verify off
col event_name for a25
col i for 9
col h_00 for 999.9
col h_01 for 999.9
col h_02 for 999.9
col h_03 for 999.9
col h_04 for 999.9
col h_05 for 999.9
col h_06 for 999.9
col h_07 for 999.9
col h_08 for 999.9
col h_09 for 999.9
col h_10 for 999.9
col h_11 for 999.9
col h_12 for 999.9
col h_13 for 999.9
col h_14 for 999.9
col h_15 for 999.9
col h_16 for 999.9
col h_17 for 999.9
col h_18 for 999.9
col h_19 for 999.9
col h_20 for 999.9
col h_21 for 999.9
col h_22 for 999.9
col h_33 for 999.9
select inst_id i,MetricDate, event_name,
       avg(metric_00) h_00,
       avg(metric_01) h_01,
       avg(metric_02) h_02,
       avg(metric_03) h_03,
       avg(metric_04) h_04,
       avg(metric_05) h_05,
       avg(metric_06) h_06,
       avg(metric_07) h_07,
       avg(metric_08) h_08,
       avg(metric_09) h_09,
       avg(metric_10) h_10,
       avg(metric_11) h_11,
       avg(metric_12) h_12,
       avg(metric_13) h_13,
       avg(metric_14) h_14,
       avg(metric_15) h_15,
       avg(metric_16) h_16,
       avg(metric_17) h_17,
       avg(metric_18) h_18,
       avg(metric_19) h_19,
       avg(metric_20) h_20,
       avg(metric_21) h_21,
       avg(metric_22) h_22,
       avg(metric_23) h_23
  from (select sn.instance_number inst_id,to_char(sn.begin_interval_time, 'YYYY-MM-DD') MetricDate, en.event_name event_name,
               decode(to_char(sn.begin_interval_time,'HH24'), '00', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_00,
               decode(to_char(sn.begin_interval_time,'HH24'), '01', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_01,
               decode(to_char(sn.begin_interval_time,'HH24'), '02', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_02,
               decode(to_char(sn.begin_interval_time,'HH24'), '03', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_03,
               decode(to_char(sn.begin_interval_time,'HH24'), '04', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_04,
               decode(to_char(sn.begin_interval_time,'HH24'), '05', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_05,
               decode(to_char(sn.begin_interval_time,'HH24'), '06', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_06,
               decode(to_char(sn.begin_interval_time,'HH24'), '07', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_07,
               decode(to_char(sn.begin_interval_time,'HH24'), '08', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_08,
               decode(to_char(sn.begin_interval_time,'HH24'), '09', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_09,
               decode(to_char(sn.begin_interval_time,'HH24'), '10', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_10,
               decode(to_char(sn.begin_interval_time,'HH24'), '11', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_11,
               decode(to_char(sn.begin_interval_time,'HH24'), '12', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_12,
               decode(to_char(sn.begin_interval_time,'HH24'), '13', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_13,
               decode(to_char(sn.begin_interval_time,'HH24'), '14', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_14,
               decode(to_char(sn.begin_interval_time,'HH24'), '15', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_15,
               decode(to_char(sn.begin_interval_time,'HH24'), '16', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_16,
               decode(to_char(sn.begin_interval_time,'HH24'), '17', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_17,
               decode(to_char(sn.begin_interval_time,'HH24'), '18', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_18,
               decode(to_char(sn.begin_interval_time,'HH24'), '19', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_19,
               decode(to_char(sn.begin_interval_time,'HH24'), '20', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_20,
               decode(to_char(sn.begin_interval_time,'HH24'), '21', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_21,
               decode(to_char(sn.begin_interval_time,'HH24'), '22', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_22,
               decode(to_char(sn.begin_interval_time,'HH24'), '23', round(avg((see.time_waited_micro-seb.time_waited_micro)/1000/(see.total_waits-seb.total_waits)), 2)) metric_23
          from sys.wrh$_event_name en, sys.wrh$_system_event seb, sys.wrh$_system_event see, sys.wrm$_snapshot sn
         where 
	   sn.begin_interval_time between to_timestamp('&2') and
                                          to_timestamp('&3')
           and sn.snap_id = see.snap_id
           and sn.dbid    = see.dbid
           and sn.instance_number = see.instance_number
           and seb.snap_id = see.snap_id - 1
           and seb.dbid = see.dbid
           and seb.instance_number = see.instance_number
           and seb.event_id = see.event_id
           and see.dbid = en.dbid
           and see.event_id = en.event_id
           and en.event_name in ('&1')
          group by sn.instance_number,to_char(sn.begin_interval_time, 'YYYY-MM-DD'), en.event_name,to_char(sn.begin_interval_time,'HH24'))
 group by inst_id,MetricDate,event_name
 order by inst_id,MetricDate
/
