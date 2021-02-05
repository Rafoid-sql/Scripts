
SET HEADING OFF 
set FEEDBACK OFF 
set OFF PAGESIZE 0
SET VERIFY OFF
set lines 155
spool /home/oracle/dropowner.lst

select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user DBAASS cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user POS_EAD cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user NFSE_NEAD cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user NFSE_EAD cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user NFSE_POS cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user OPENFIRE cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user OPENFIRENET cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user OLIMPOINTEGRA cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
drop user NFSE_NDD cascade;
select to_char(sysdate,'hh24:mi:ss dd-mm-yyyy') from dual;
SET HEADING ON 
set FEEDBACK ON
SET VERIFY ON
spool off