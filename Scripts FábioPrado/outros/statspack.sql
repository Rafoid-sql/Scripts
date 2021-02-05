
### Criar tablespace para o statspack

create tablespace TAB_MARCELO datafile '/u01/oradata/orahom/tabmarcelo01.dbf' size 200m autoextend on next 100m maxsize 5000m;
alter tablespace STATSPACK add datafile '/u01/oradata/orahom/statspack02.dbf' size 200m autoextend on next 100m maxsize 5000m;

### criar o usuário PERFSTAT

@?/rdbms/admin/spcreate.sql


### Coleta automatica

@?/rdbms/admin/spauto.sql

### procedure para purge dos snapshots

create or replace procedure statspackpurge is
var_lo_snap number;
var_hi_snap number;
var_db_id number;
var_instance_no number;
noofsnapshot number;
n_count number ;
begin
 
n_count := 0;
 
select count(*) into n_count from stats$snapshot where snap_time < sysdate-7; 
if n_count > 0 then
 
select min(s.snap_id) , max(s.snap_id),max(di.dbid),max(di.instance_number) into var_lo_snap, var_hi_snap,var_db_id,var_instance_no
 from stats$snapshot s
 , stats$database_instance di
 where s.dbid = di.dbid
 and s.instance_number = di.instance_number
 and di.startup_time = s.startup_time
 and s.snap_time < sysdate-7; 
 noofsnapshot := statspack.purge( i_begin_snap => var_lo_snap
 , i_end_snap => var_hi_snap
 , i_snap_range => true
 , i_extended_purge => false
 , i_dbid => var_db_id
 , i_instance_number => var_instance_no);
 
 dbms_output.Put_line('snapshot deleted'||to_char(noofsnapshot));
 
end if;
end;
/

### jobs para limpeza diaria

declare
  my_job number;
begin
  dbms_job.submit(job => my_job,
    what => 'statspackpurge;',
    next_date => trunc(sysdate)+1,
    interval => 'trunc(sysdate)+1');
end;
/

### Gerar relatorio statspack

@?/rdbms/admin/spreport.sql

### Relatorio de um unico SQLCODE

@?/rdbms/admin/sprepsql.sql

### Coleta manual

EXEC STATSPACK.snap

### Proxima execução Job

col NEXT_DATE for a25
col interval for a25
col WHAT for a55
select JOB, to_char(NEXT_DATE,'dd/mm/yyyy hh24:mi:ss') as Next_Date, INTERVAL from dba_jobs;

### Snapshot existente

select SNAP_ID, to_char(SNAP_TIME, 'dd/mm/yyyy hh24:mi:ss') as SNAP_TIME  from STATS$SNAPSHOT;


### alterar nivel do statspack

EXECUTE STATSPACK.SNAP(i_snap_level=>5, i_modify_parameter=>'true');

### baixar o intervalo de coleta e aumentar o tempo de armazenamento

EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS (RETENTION=>86400, INTERVAL=>30, TOPNSQL=>100);