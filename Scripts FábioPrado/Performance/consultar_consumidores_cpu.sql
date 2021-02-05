set lines 155
set pagesize 150
SELECT s.sid, s.serial#, p.spid as "OS PID",s.username, s.module,
st.value/100 as "CPU sec"
FROM v$sesstat st, v$statname sn, v$session s, v$process p WHERE sn.name = 'CPU used by this session' 
AND st.statistic# = sn.statistic# 
AND st.sid = s.sid AND s.paddr = p.addr AND s.last_call_et < 1800
AND s.logon_time > (SYSDATE-(240/1440)) ORDER BY st.value desc;




set lines 155
set pagesize 150
SELECT s.sid, s.serial#, s.username, s.STATUS, sq.ELAPSED_TIME/1000000/60 MINUTOS, sq.ELAPSED_TIME/1000000/60 HORAS
FROM v$sesstat st, v$statname sn, v$session s, v$sql sq, v$process p WHERE  
--st.statistic# = sn.statistic# 
--st.sid = s.sid AND s.paddr = p.addr AND s.sql_id = sq.sql_id
--AND s.logon_time > (SYSDATE-(240/1440)) 
s.status = 'ACTIVE' AND
s.username NOT IN ('USER_SIUD','SYS') ORDER BY st.value desc;



-- query e tempo de execução passando sid

SELECT OSUSER, SERIAL#, SID, executions, sql.SQL_ID ,sql.child_number, SQL_TEXT, sql.ELAPSED_TIME/1000000/60 MINUTOS, sql.ELAPSED_TIME/1000000/60/60 HORAS
FROM V$SESSION sess JOIN V$SQL sql 
on  (sess.SQL_ADDRESS = sql.ADDRESS) 
where sess.STATUS = 'ACTIVE' and
sess.sid = 1438;