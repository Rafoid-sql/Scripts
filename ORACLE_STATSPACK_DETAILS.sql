--### ORACLE STATSPACK ###--

--SELECT SNAPSHOTS
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';
col host_name format a30
select distinct snap.snap_id, snap.snap_time, snap.dbid, di.db_name, snap.instance_number, di.instance_name, di.host_name
from stats$snapshot snap, stats$database_instance di
where di.dbid = snap.dbid
and snap.instance_number = di.instance_number
and snap_time > sysdate-7
--and di.instance_number=1
order by 2;

select distinct snap.snap_id, snap.snap_time, snap.dbid, di.db_name, snap.instance_number, di.instance_name, di.host_name
from stats$snapshot snap, stats$database_instance di
where di.dbid = snap.dbid
and snap.instance_number = di.instance_number
and snap_time > sysdate-1
and di.instance_number=1
order by 2;

----------------

--PURGE MANUAL

exec statspack.purge( i_begin_snap => 696, i_end_snap => 734, i_snap_range => true, i_extended_purge => false, i_dbid => 1838110350, i_instance_number => 1);

----------------

--CRIACAO (INCOMPLETO)

--Executar script:

SQL> @?/rdbms/admin/spcreate.sql


----------------

--JOB PARA CRIACAO DE SNAPSHOTS - CRIA UM JOB (ANTIGO), TODO O PROCEDIMENTO FOI ALTERADO PARA EXECUTAR VIA SCHEDULER:

-- CRIA O JOB AUTOMATICAMENTE, PARA RODAR A CADA 1H:
#@?/rdbms/admin/spauto.sql

--1h
#variable v_JobNo number;
#execute dbms_job.submit(:v_JobNo, 'statspack.snap;',TRUNC(SYSDATE+(1/24),'HH'),'trunc(SYSDATE+1/24,''HH24'')'); commit;

--30min
#variable v_JobNo number;
#execute dbms_job.submit(:v_JobNo, 'statspack.snap;',TRUNC(SYSDATE+(1/24),'HH'),'TRUNC(SYSDATE+(30/24/60),''MI'')'); commit;


-----

--CRIACAO DE SNAPSHOT VIA SCHEDULER, EXEMPLO PARA RAC, CRIAR UM POR INSTANCIA

#### ATENÇÃO ####
#
# CASO SEJA RAC, DEIXAR UMA PEQUENA DIFERENCA NO HORARIO DE EXECUCAO DOS NODES PARA EVITAR CONCORRENCIA NOS OBJETOS DO STATSPACK
# no caso abaixo, a instância 2 esta configurada para tirar um snapshot toda hora, no minuto 05, enquanto a instancia 1, no minuto 00
#
#################

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
job_name => 'snap_inst_1',
job_type => 'STORED_PROCEDURE',
job_action => 'statspack.snap',
repeat_interval => 'FREQ=HOURLY; BYMINUTE=0',
auto_drop => FALSE,
enabled => TRUE,
comments => 'Statspack automated snap - instance 1');
END;
/

begin
dbms_scheduler.set_attribute('snap_inst_2','instance_id',2);
end;
/

----


--exec dbms_scheduler.set_attribute('PURGE_SNAPSHOTS','JOB_TYPE','STORED_PROCEDURE');

--PROCEDURE PARA PURGE DE SNAPSHOTS: #### SUBSTITUIDA POR NOVA, ATUALIZADA PRA FUNCIONAR EM RAC TAMBÉM
#create or replace procedure statspackpurge is
#var_lo_snap number;
#var_hi_snap number;
#var_db_id number;
#var_instance_no number;
#noofsnapshot number;
#n_count number ;
#begin
# 
#n_count := 0;
# 
#select count(*) into n_count from stats$snapshot where snap_time < sysdate-7; 
#if n_count > 0 then
# 
#select min(s.snap_id) , max(s.snap_id),max(di.dbid),max(di.instance_number) 
#into var_lo_snap, var_hi_snap,var_db_id,var_instance_no
# from stats$snapshot s, stats$database_instance di
# where s.dbid = di.dbid
# and s.instance_number = di.instance_number
# and di.startup_time = s.startup_time
# and s.snap_time < sysdate-7; 
# noofsnapshot := statspack.purge( i_begin_snap => var_lo_snap
# , i_end_snap => var_hi_snap
# , i_snap_range => true
# , i_extended_purge => false
# , i_dbid => var_db_id
# , i_instance_number => var_instance_no);

 
# dbms_output.put_line('snapshot deleted: '||to_char(noofsnapshot));
# 
#end if;
#end;
#/

--PROCEDURE PARA PURGE DE SNAPSHOTS (RAC):
create or replace procedure statspackpurge is
var_lo_snap number;
var_hi_snap number;
var_db_id number;
var_instance_no number;
noofsnapshot number;
n_count number ;
begin

FOR inst_no in (select distinct instance_number from stats$snapshot)
LOOP

n_count := 0;
 
select count(*) into n_count from stats$snapshot where snap_time < sysdate-7 and instance_number = inst_no.instance_number; 
if n_count > 0 then
 
select min(s.snap_id) , max(s.snap_id),max(di.dbid)
into var_lo_snap, var_hi_snap,var_db_id
 from stats$snapshot s, stats$database_instance di
 where s.dbid = di.dbid
 and s.instance_number = inst_no.instance_number
 and s.instance_number = di.instance_number
 and di.startup_time = s.startup_time
 and s.snap_time < sysdate-7; 
 noofsnapshot := statspack.purge( i_begin_snap => var_lo_snap
 , i_end_snap => var_hi_snap
 , i_snap_range => true
 , i_extended_purge => false
 , i_dbid => var_db_id
 , i_instance_number => inst_no.instance_number);

 
 dbms_output.put_line('instance: '||inst_no.instance_number||' / snapshot deleted: '||to_char(noofsnapshot));
 
end if;

END LOOP;

end;
/

----

--JOB PARA EXECUCAO DE PURGE:

declare
  my_job number;
begin
  dbms_job.submit(job => my_job,
    what => 'statspackpurge;',
    next_date => trunc(sysdate)+1,
    interval => 'trunc(sysdate)+1');
end;
/

--SCHEDULER:

BEGIN
sys.dbms_scheduler.create_job( 
job_name => 'PURGE_SNAPSHOTS',
job_type => 'STORED_PROCEDURE',
job_action => 'statspackpurge',
repeat_interval => 'FREQ=DAILY;BYHOUR=6;BYMINUTE=0',
start_date => SYSTIMESTAMP,
job_class => 'DEFAULT_JOB_CLASS',
comments => 'FAZ O PURGE DE SNAPSHOTS DO STATSPACK',
auto_drop => FALSE,
enabled => TRUE);
END;
/

## CHANGING JOB REPEAT_INTERVAL / SCHEDULE / FREQUENCY

begin
dbms_scheduler.set_attribute('PURGE_SNAPSHOTS','REPEAT_INTERVAL','FREQ=DAILY;BYHOUR=6;BYMINUTE=0');
end;
/

--------
--------
--------
--------

--TESTE PARA PEGAR A INSTANCIA E PODER CRIAR 1 PURGE PARA CADA INSTANCIA NO RAC:

set serveroutput on
declare
var_instance_no number;
var_istance_name varchar2(40);
begin

select instance_number into var_instance_no from v$instance;
select instance_name  into var_istance_name from v$instance
where instance_number=var_instance_no;

 dbms_output.put_line('instance_number: '||var_instance_no||' / instance_name: '||var_istance_name);

end;
/

--SUBSTITUIR SELECT ACIMA:

/*select min(s.snap_id) , max(s.snap_id),max(di.dbid),ins.instance_number 
into var_lo_snap, var_hi_snap,var_db_id,var_instance_no
from stats$snapshot s, stats$database_instance di, v$instance ins
where s.dbid = di.dbid
and s.instance_number = di.instance_number
and ins.instance_number = s.instance_number
and di.startup_time = s.startup_time
and s.snap_time < sysdate-7
group by ins.instance_number;*/


conn perfstat
select JOB_NAME, INSTANCE_ID, instance_stickiness, PROGRAM_NAME, JOB_TYPE,START_DATE,REPEAT_INTERVAL,END_DATE,ENABLED,STATE,RUN_COUNT,FAILURE_COUNT,LAST_START_DATE,LAST_RUN_DURATION,NEXT_RUN_DATE,JOB_ACTION
from user_scheduler_jobs
WHERE ENABLED='TRUE';









