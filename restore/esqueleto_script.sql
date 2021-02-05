/*
--------------------------
-- configuracoes iniciais
--------------------------
*/

set timing on echo on feedback on lines 133
alter session set nls_date_format = 'dd/mm/yy hh24:mi:ss';
col instancia for a10
col usuario for a35

-- criacao nome arquivo de log

DEFINE CHAMADO = "RSTESTE" -- NUMERO DA requisição/mudança etc
colum fname new_value filename noprint

SELECT '&CHAMADO' || '-' || SYS_CONTEXT('USERENV','DB_NAME') || '-' || UPPER(USER) || '-' || 
       replace(substr(SYS_CONTEXT('USERENV', 'HOST'),1,15),'.','_') || '-' || TO_CHAR(SYSDATE, 'yymmdd_hh24miss') || '.log' fname 
  FROM DUAL;
spool &filename

-- 

set lines 80 
/*
----------------------------
-- coloque aqui o seu script
----------------------------
*/

-- Inicio



-- Fim

/

/*
--------------------------------------
-- ATENCAO: nao remova o commit abaixo
--------------------------------------
*/

COMMIT  

/

----------
-- fim log
----------

set lines 133
col host_name for a60
select USER USUARIO, SYS_CONTEXT('USERENV','DB_NAME') INSTANCIA, SYS_CONTEXT('USERENV', 'HOST') host_name, sysdate DATA_HORA 
  from dual;

spool off
    
