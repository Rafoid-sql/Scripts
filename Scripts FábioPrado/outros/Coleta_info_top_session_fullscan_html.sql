PROMPT Coleta Informacoes Premier
PROMPT DBA Maycon Tomiasi
PROMPT Empresa: Teiko Solucoes em TI
PROMPT Arquivo: Coleta_info_top_session_fullscan_html.sql
PROMPT Versao do Script: 1.2
PROMPT Data Criacao 05/07/2011 09:00
PROMPT Data Alteracao 10/08/2015 11:00 RBEIMS
PROMPT Data Alteracao 06/01/2016 14:00 RBEIMS
PROMPT Data Alteracao 12/01/2016 14:00 RBEIMS
PROMPT Data Alteracao 09/03/2016 09:00 RBEIMS -Acertos

alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';

COLUMN NAME1 NEW_VALUE SID_ORACLE1 NOPRINT
SELECT NAME NAME1 FROM V$DATABASE;

COLUMN NAME2 NEW_VALUE SID_ORACLE2 NOPRINT
SELECT NAME||'.html' NAME2 FROM V$DATABASE;

-- Teiko - Premier - Top SQL
set long 100000000
set pagesize 49999
set markup HTML on spool on ENTMAP OFF
TTITLE CENTER BOLD 'CONSULTORIA PREMIER --- COMANDOS TOP SQL --- Base de dados ' SID_ORACLE1 SKIP CENTER ' '
SPOOL Comandos_Top_Sql_&SID_ORACLE2
PROMPT <label><img src='http://www.teiko.com.br/agenda/TeikoMail.jpg' width='1356' height='127'><TITLE>Teiko - Consultoria Premier</TITLE> </label>
SELECT SQL_HASH_VALUE, SQL_ADDRESS,  SID, SERIAL#, USERNAME, OSUSER, MACHINE, MODULE, PROGRAM, TIME_COMMAND, TIMESTAMP, SQL_TEXT
FROM   TEIKOADM.TK_VW_TOP_SQLTEXT_MR
WHERE  USERNAME not in ('TEIKOADM','TEIKOBKP','SYS')
--AND TO_CHAR(TIMESTAMP, 'D') NOT IN (1, 7)
--AND TO_CHAR(TIMESTAMP, 'HH24') BETWEEN (select SUBSTR(VALUE, 1, 2)
--                                        from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 26)
--                               AND     (select SUBSTR(VALUE, 4, 2)
--                                        from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 26)
AND TO_CHAR(TIMESTAMP, 'YYYYMM') = TO_CHAR(ADD_MONTHS(SYSDATE,-1),'YYYYMM')
AND ROWNUM < 21
ORDER BY TIME_COMMAND DESC;
SPOOL off
set markup HTML off

-- Teiko - Premier - Full Table Scan
set long 100000000
set pagesize 49999
set markup HTML on spool on ENTMAP OFF
TTITLE CENTER BOLD 'CONSULTORIA PREMIER --- COMANDOS FULL TABLE SCAN --- Base de dados ' SID_ORACLE1 SKIP CENTER ' '
SPOOL Comandos_Full_Table_Scan_&SID_ORACLE2
PROMPT <label><img src='http://www.teiko.com.br/agenda/TeikoMail.jpg' width='1356' height='127'><TITLE>Teiko - Consultoria Premier</TITLE> </label>
SELECT SQL_ADDRESS, SID, SERIAL#, USERNAME, OSUSER, EVENT, MODULE, PROGRAM, LAST_CALL_ET, TIMESTAMP, SQL_TEXT
FROM   TEIKOADM.TK_VW_FULL_SCAN_SQLTEXT_MR
WHERE  USERNAME not in ('TEIKOADM','TEIKOBKP','SYS')
--AND TO_CHAR(TIMESTAMP, 'D') NOT IN (1, 7)
--AND TO_CHAR(TIMESTAMP, 'HH24') BETWEEN (select SUBSTR(VALUE, 1, 2)
--                                        from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 26)
--                               AND     (select SUBSTR(VALUE, 4, 2)
--                                        from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 26)
AND LAST_CALL_ET > (select VALUE from TEIKOADM.TK_ENVIRONMENT_PARAMETERS where ID_PARAMETER = 40)
AND TO_CHAR(TIMESTAMP, 'YYYYMM') = TO_CHAR(ADD_MONTHS(SYSDATE,-1),'YYYYMM')
AND ROWNUM < 21
ORDER BY LAST_CALL_ET DESC;
SPOOL off
set markup HTML off
exit