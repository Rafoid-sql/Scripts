-------------------------------------
-- CONFIGURACOES INICIAIS
-------------------------------------

SET TIMING ON ECHO ON FEEDBACK ON LINES 133
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YY HH24:MI:SS';
COL INSTANCIA FOR A10
COL USUARIO FOR A35

-------------------------------------
-- CRIACAO NOME ARQUIVO DE LOG
-------------------------------------

DEFINE CHAMADO = "RSTESTE" -- NUMERO DA REQUISIÇÃO/MUDANÇA ETC
COLUM FNAME NEW_VALUE FILENAME NOPRINT

SELECT 
	'&CHAMADO' ||'-'|| SYS_CONTEXT('USERENV','DB_NAME') ||'-'|| UPPER(USER) ||'-'|| REPLACE(SUBSTR(SYS_CONTEXT('USERENV', 'HOST'),1,15),'.','_') ||'-'|| TO_CHAR(SYSDATE, 'YYMMDD_HH24MISS') || '.log' "FNAME" 
FROM 
	DUAL;
	
	
SPOOL &FILENAME

SET LINES 80 

-------------------------------------
-- INSIRA O SCRIPT NO ESPACO ABAIXO
-------------------------------------

-------------------------------------
-- [INICIO]





-- [FIM]
-------------------------------------

/

-- ATENCAO: *** NAO REMOVA O COMMIT ABAIXO ***

COMMIT  
/

-------------------------------------
-- FIM LOG
-------------------------------------

SET LINES 133
COL HOST_NAME FOR A60
SELECT 
	USER "USUARIO",
	SYS_CONTEXT('USERENV','DB_NAME') "INSTANCIA",
	SYS_CONTEXT('USERENV', 'HOST') "HOST_NAME", 
	SYSDATE "DATA_HORA" 
FROM
	DUAL;

SPOOL OFF
    
