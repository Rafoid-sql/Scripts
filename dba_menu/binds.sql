set verify off head off
select 'var '||replace(name,':','')||' '||datatype_string from v$sql_bind_capture where sql_id = '&1'
union all
select distinct 'exec '||name||' := '||decode(datatype_String,'NUMBER','',chr(39))||value_String||decode(datatype_String,'NUMBER','',chr(39)) from v$sql_bind_capture
where sql_id = '&1';

undefine 1
set head on
