--VERIFICAR SENHAS:
SET LINES 300
COL NM_USER FORMAT A20
COL DS_SENHA FORMAT A50
COL NM_USUARIO FORMAT A10
COL DT_ATUALIZACAO FORMAT A15
SELECT NM_USER,DS_SENHA,NM_USUARIO,DT_ATUALIZACAO FROM TASY_VERSAO.TASY_SEG;


--VERIFICAR MUDANÇAS:
SET LINES 300
COL NR_SEQUENCIA FORMAT 9999999
COL DT_ATUALIZACAO FORMAT A15
COL NM_USUARIO FORMAT A20
COL NM_MAQUINA A 20
SELECT NR_SEQUENCIA,DT_ATUALIZACAO,NM_USUARIO,NM_MAQUINA  FROM TASY.LOG_ALT_SENHA_BANCO ORDER BY NR_SEQUENCIA;