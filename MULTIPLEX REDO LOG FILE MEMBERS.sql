DECLARE
BEGIN
for rec in (select group# the_group, substr(member, 1, instr(member, '.', -1)-1)|| 'b.log' multiplexed_member from V$LOGFILE)
loop
	execute immediate 'alter database add logfile member ''' || rec.multiplexed_member || ''' to group ' || rec.the_group || ''; 
end loop;

END;
/
exit
