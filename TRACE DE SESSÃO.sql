
SET LINES 300 PAGESIZE 2000
SELECT SUBSTR(A.SPID,1,9) PID, SUBSTR(B.SID,1,5) SID, SUBSTR(B.SERIAL#,1,5) SER#, SUBSTR(B.MACHINE,1,25) BOX, SUBSTR(B.USERNAME,1,10) USERNAME, SUBSTR(B.CLIENT_INFO,1,40) CLIENT, SUBSTR(B.OSUSER,1,20) OS_USER, SUBSTR(B.PROGRAM,1,40) PROGRAM, SUBSTR(B.STATUS,1,10) STATUS FROM V$SESSION B, V$PROCESS A WHERE B.PADDR = A.ADDR AND TYPE='USER'
--AND B.USERNAME IN ('USER_SIUD')
--AND B.PROGRAM LIKE ('%Piramide%')
--AND CLIENT_INFO LIKE ('%69237192%')
AND OSUSER LIKE ('%svo-credenciamento1%')
--AND MACHINE IN ('HMRT\SERVER_DELL')
ORDER BY SID;
-------------------------------------------------------------------------------------------------------------------------------
--LIGAR/DESLIGAR TRACE:
EXECUTE DBMS_MONITOR.SESSION_TRACE_ENABLE(SESSION_ID=>1063,SERIAL_NUM=>54201,WAITS=>TRUE,BINDS=>TRUE);
EXECUTE DBMS_MONITOR.SESSION_TRACE_DISABLE(SESSION_ID=>1063,SERIAL_NUM=>54201);
-------------------------------------------------------------------------------------------------------------------------------
-- ORACLE 11G:
SELECT B.SID,B.SERIAL#,A.PID,A.PROGRAM,A.TRACEFILE FROM GV$PROCESS  A, GV$SESSION B WHERE A.ADDR = B.PADDR
AND B.SID=1063 AND B.SERIAL#=54201;
--AND tracefile='/u01/app/oracle/diag/rdbms/cdbhom1/cdbhom12/trace/cdbhom12_ora_159844_reqtestehomol.trc';

-- ORACLE 10G:
cd $ORACLE_BASE/admin/$ORACLE_SID/udump
-------------------------------------------------------------------------------------------------------------------------------

      1063      54201        371 oracle@serverdb
/u01/app/oracle/diag/rdbms/grupofila/grupofila/trace/grupofila_ora_9512.trc

-------------------------------------------------------------------------------------------------------------------------------
--COMANDOS TKPROF:
--tkprof NOVA_ora_16246.trc NOVA_ora_16246_fchela.txt WAITS=YES SYS=YES SORT=FCHELA
--tkprof NOVA_ora_16246.trc NOVA_ora_16246.txt WAITS=YES SYS=YES SORT=PRSCNT,EXECNT,FCHCNT,PRSELA,EXEELA,FCHELA,PRSCPU,EXECPU,FCHCPU

PRSCNT	Number of times parsed.
PRSCPU	CPU time spent parsing.
PRSELA	Elapsed time spent parsing.
PRSDSK	Number of physical reads from disk during parse.
PRSQRY	Number of consistent mode block reads during parse.
PRSCU		Number of current mode block reads during parse.
PRSMIS	Number of library cache misses during parse.
EXECNT	Number of executes.
EXECPU	CPU time spent executing.
EXEELA	Elapsed time spent executing.
EXEDSK	Number of physical reads from disk during execute.
EXEDSK	Number of physical reads from disk during execute.
EXEQRY	Number of consistent mode block reads during execute.
EXECU		Number of current mode block reads during execute.
EXEROW	Number of rows processed during execute.
EXEMIS	Number of library cache misses during execute.
FCHCNT	Number of fetches.
FCHCPU	CPU time spent fetching.
FCHELA	Elapsed time spent fetching.
FCHDSK	Number of physical reads from disk during fetch.
FCHQRY	Number of consistent mode block reads during fetch.
FCHCU		Number of current mode block reads during fetch.
FCHROW	Number of rows fetched.