CREATE OR REPLACE NONEDITIONABLE TRIGGER SYS.BLOCK_TOOLS_FROM_PROD AFTER LOGON ON DATABASE
 DECLARE
 v_prog sys.v_$session.program%TYPE;
 owner sys.v_$session.username%TYPE;
  2    3    4    5   v_osuser sys.v_$session.osuser%TYPE;
 BEGIN
  6    7   SELECT program, username, osuser
 INTO v_prog, owner, v_osuser
 FROM sys.v_$session
 WHERE audsid = USERENV('SESSIONID')
 AND audsid != 0 -- NÃ¿Â£o verificar conexÃ¿Âµes SYS
 AND rownum = 1; -- Processos paralelos terÃ¿Â¡ o mesmo do AUDSID
IF UPPER(owner) IN ('USER_SIUD','USER_S','OPENFIRE','POS_EAD')
 THEN
 IF UPPER(v_prog) LIKE '%TOAD%' OR
 UPPER(v_prog) LIKE '%T.O.A.D%' OR -- Toad
 UPPER(v_prog) LIKE '%SQLNAV%' OR -- SQL Navigator
 UPPER(v_prog) LIKE '%PLSQLDEV%' OR -- PLSQL Developer
 UPPER(v_prog) LIKE '%BUSOBJ%' OR -- Business Objects
 UPPER(v_prog) LIKE '%MSACCESS%' OR -- MS-ACCESS
 UPPER(v_prog) LIKE '%EXCEL%' OR -- MS-Excel plug-in
-- UPPER(v_prog) LIKE '%SQLPLUS%' OR -- SQLPLUS
 UPPER(v_prog) LIKE '%DEVELOPER%' -- Oracle SQL Developer
 UPPER(v_prog) LIKE '%IFBLD%' OR -- Oracle Forms Developer Builder
 UPPER(v_prog) LIKE '%RWBUILDER%' OR -- Oracle Reports Builder
 UPPER(v_prog) LIKE '%RAPTOR%' -- Oracle Raptor
 THEN
 RAISE_APPLICATION_ERROR(-20000, 'Ferraments de desenvolvimento nao sao permitidas na PRODUCAO! ('||v_osuser||' - '||owner||' - '||v_prog||')');
 END IF;
END IF;
 EXCEPTION
 WHEN NO_DATA_FOUND THEN NULL;
 END;
