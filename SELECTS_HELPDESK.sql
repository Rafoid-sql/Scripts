--FECHAMENTO DE HORAS CLIENTE/MÊS
set lines 200 pagesize 80
col empresa format a30
SELECT empresa, horas_contratadas, lpad(HORAS+TRUNC((MINUTOS/60)),2,'0') ||':'|| 
       lpad((CASE WHEN MINUTOS >= 60 THEN MINUTOS-(TRUNC((MINUTOS/60))*60) ELSE MINUTOS END),2,'0') horas
  FROM (
  SELECT empresa, horas_contratadas, 
       SUM(EXTRACT (HOUR FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) HORAS, 
       SUM(EXTRACT (MINUTE FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) MINUTOS
  FROM (  
SELECT empresa.nome empresa, empresa.horas_contratadas, et.data_inicio di, et.data_fim df,
       CASE WHEN (ET.DATA_INICIO < TRUNC(to_date('01/&&mes/&&ano','dd/mm/yyyy') )) THEN TRUNC(to_date('01/&&mes/&&ano','dd/mm/yyyy') ) ELSE ET.DATA_INICIO END DATA_INICIO,
       CASE WHEN (ET.DATA_FIM IS NULL or et.DATA_FIM > LAST_DAY(TO_DATE('01/&&mes/&&ano 23:59:59','dd/mm/yyyy hh24:mi:ss'))) THEN LAST_DAY(TO_DATE('01/&&mes/&&ano 23:59:59','dd/mm/yyyy hh24:mi:ss')) ELSE ET.DATA_FIM END DATA_FIM
  FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.FILIAL, HELPDESK.EMPRESA, HELPDESK.solicitacao
 WHERE ET.TAREFA_ID = TAREFA.ID
   and solicitacao.id = tarefa.solicitacao_id
  and solicitacao.filial_id = filial.id
  and filial.empresa_id = empresa.id
and empresa.horas_contratadas is not null
   AND (et.data_inicio between to_date('01/&&mes/&&ano','dd/mm/yyyy') and LAST_DAY(TO_DATE('01/&&mes/&&ano 23:59:59','dd/mm/yyyy hh24:mi:ss'))
         or nvl(et.data_fim,sysdate) between to_date('01/&&mes/&&ano','dd/mm/yyyy') and LAST_DAY(TO_DATE('01/&&mes/&&ano 23:59:59','dd/mm/yyyy hh24:mi:ss')))
) group by empresa, horas_contratadas
) order by empresa;

--HORAS EXECUTADAS POR DIA POR ANALISTA
set lines 200 pagesize 80
col nome format a40
SELECT DATA_INICIO, NOME, HORAS+TRUNC((MINUTOS/60)) HORAS,
CASE WHEN MINUTOS >= 60 THEN MINUTOS-(TRUNC((MINUTOS/60))*60) ELSE MINUTOS END MINUTOS
 FROM (
    SELECT TRUNC(DATA_INICIO) as DATA_INICIO, NOME, SUM(EXTRACT (HOUR FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) HORAS,
          SUM(EXTRACT (MINUTE FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) MINUTOS
     FROM ( 
        SELECT USUARIO.NOME, et.data_inicio di, et.data_fim df,
          CASE WHEN (ET.DATA_INICIO < TRUNC(DIAS.DIA)) THEN TRUNC(DIAS.DIA) ELSE ET.DATA_INICIO END DATA_INICIO,
          CASE WHEN (et.DATA_FIM > to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS'))
            THEN to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') ELSE NVL(ET.DATA_FIM,SYSDATE) END DATA_FIM
        FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL,helpdesk.grupo gru, helpdesk.grupo_usuario gusu,
          (SELECT data_inicial + LEVEL - 1 dia
            FROM (SELECT TO_DATE('&&data_inicial', 'DD/MM/YYYY') data_inicial FROM dual)
              CONNECT BY LEVEL <= TO_DATE('&data_final', 'DD/MM/YYYY') - TO_DATE('&&data_inicial', 'DD/MM/YYYY') + 1) dias
            WHERE ET.TAREFA_ID = TAREFA.ID
              AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
              AND USUARIO.FILIAL_ID = FILIAL.ID
              AND FILIAL.EMPRESA_ID = 1
              AND TRUNC(DIAS.DIA) BETWEEN TRUNC(ET.DATA_INICIO) AND TRUNC(NVL(ET.DATA_FIM,SYSDATE))
              and USUARIO.ID=gusu.usuario_id
              and gusu.grupo_id=gru.id 
              and gru.id=63
              and TAREFA.situacao not in ('S')
              --AND TRUNC(et.DATA_FIM)>trunc(et.data_inicio)
    --ORDER BY NOME, DIAS.DIA
) 
      GROUP BY TRUNC(DATA_INICIO),NOME
) 
order by 1,2;

-- HORAS EXECUTADAS/MÊS/ANALISTA
set lines 200 pagesize 80
col nome format a40
SELECT DATA_INICIO, NOME, HORAS+TRUNC((MINUTOS/60)) HORAS,
--CASE WHEN MINUTOS >= 60 THEN MINUTOS-(TRUNC((MINUTOS/60))*60) ELSE MINUTOS END MINUTOS --MINUTOS
CASE WHEN MINUTOS >= 60 THEN (MINUTOS-(TRUNC((MINUTOS/60))*60))/60*100 ELSE MINUTOS END MINUTOS -- MINUTOS DECIMAL
 FROM (
    SELECT TRUNC(DATA_INICIO,'MONTH') as DATA_INICIO, NOME, SUM(EXTRACT (HOUR FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) HORAS,
          SUM(EXTRACT (MINUTE FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) MINUTOS
     FROM ( 
        SELECT USUARIO.NOME, ET.data_inicio di, ET.data_fim df,
          CASE WHEN (ET.DATA_INICIO < TRUNC(DIAS.DIA)) THEN TRUNC(DIAS.DIA) ELSE ET.DATA_INICIO END DATA_INICIO,
          CASE WHEN (ET.DATA_FIM > to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS'))
            THEN to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') ELSE NVL(ET.DATA_FIM,SYSDATE) END DATA_FIM
        FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL,helpdesk.grupo gru, helpdesk.grupo_usuario gusu,
          (SELECT data_inicial + LEVEL - 1 dia
            FROM (SELECT TO_DATE('01/&&mes/&&ano', 'DD/MM/YYYY') data_inicial FROM dual)
              CONNECT BY LEVEL <= LAST_DAY(TO_DATE('01/&&mes/&&ano', 'DD/MM/YYYY')) - TO_DATE('01/&&mes/&&ano', 'DD/MM/YYYY') + 1) dias
            WHERE ET.TAREFA_ID = TAREFA.ID
              AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
              AND USUARIO.FILIAL_ID = FILIAL.ID
              AND FILIAL.EMPRESA_ID = 1
              AND TRUNC(DIAS.DIA) BETWEEN TRUNC(ET.DATA_INICIO) AND TRUNC(NVL(ET.DATA_FIM,SYSDATE))
              and USUARIO.ID=gusu.usuario_id
              and gusu.grupo_id=gru.id
              and gru.id=63
              and TAREFA.situacao not in ('S')
              --AND TRUNC(et.DATA_FIM)>trunc(et.data_inicio)
    --ORDER BY NOME, DIAS.DIA
) 
      GROUP BY TRUNC(DATA_INICIO,'MONTH'),NOME
) 
order by 1,2;

--HORAS EXECUTADAS NO MÊS POR TAREFA E ANALISTA ESPECIFICO

SELECT ID,TRUNC(DATA_INICIO) as DATA_INICIO, NOME, SUM(EXTRACT (HOUR FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) HORAS,
	SUM(EXTRACT (MINUTE FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) MINUTOS
FROM ( 
	SELECT TAREFA.ID ,USUARIO.NOME, ET.data_inicio di, ET.data_fim df,
		CASE WHEN (ET.DATA_INICIO < TRUNC(DIAS.DIA)) THEN TRUNC(DIAS.DIA) ELSE ET.DATA_INICIO END DATA_INICIO,
		CASE WHEN (ET.DATA_FIM > to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS'))
		THEN to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') ELSE NVL(ET.DATA_FIM,SYSDATE) END DATA_FIM
	FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL,helpdesk.grupo gru, helpdesk.grupo_usuario gusu,
		(SELECT data_inicial + LEVEL - 1 dia
		FROM (SELECT TO_DATE('01/&&mes/&&ano', 'DD/MM/YYYY') data_inicial FROM dual)
		CONNECT BY LEVEL <= LAST_DAY(TO_DATE('01/&&mes/&&ano', 'DD/MM/YYYY')) - TO_DATE('01/&&mes/&&ano', 'DD/MM/YYYY') + 1) dias
		WHERE ET.TAREFA_ID = TAREFA.ID
		AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
		AND USUARIO.FILIAL_ID = FILIAL.ID
		AND FILIAL.EMPRESA_ID = 1
		AND TRUNC(DIAS.DIA) BETWEEN TRUNC(ET.DATA_INICIO) AND TRUNC(NVL(ET.DATA_FIM,SYSDATE))
		and USUARIO.ID=gusu.usuario_id
		and gusu.grupo_id=gru.id
		and gru.id=63
		and usuario.nome like 'Leonardo%'
		and TAREFA.situacao not in ('S')
)
GROUP BY ID,TRUNC(DATA_INICIO),NOME;

--CHAMADOS ENCERRADOS HOJE

set lines 200 pagesize 80
col analista format a30
col criador_tarefa format a20
col filial format a20
select to_char(DATA_ENCERRADO, 'DD/MM/YYYY') dia, solicitacao.situacao, filial.nome filial, criador.nome criador_tarefa,atendente.nome analista, classe.descricao, count(solicitacao.id) quant
from helpdesk.solicitacao, helpdesk.usuario atendente, helpdesk.classe, helpdesk.usuario criador, helpdesk.filial
where solicitacao.ENCERROU_USUARIO_ID = atendente.id
and criador.id=solicitacao.CRIOU_USUARIO_ID
and filial.id = solicitacao.filial_id
and atendente.id in 
	(select usu.id
	from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
	where usu.situacao='A'
	and usu.filial_id=1
	and usu.filial_id=fil.id
	and usu.id=gusu.usuario_id
	and gusu.grupo_id=gru.id
	and gru.id=63  )
and solicitacao.CLASSE_FINAL_ID = classe.id
and (DATA_ENCERRADO >= TRUNC(SYSDATE) OR solicitacao.situacao in ('S','X'))
group by to_char(DATA_ENCERRADO, 'DD/MM/YYYY'), solicitacao.situacao, filial.nome,criador.nome, atendente.nome , classe.descricao
order by dia, analista;


--CHAMADOS ENCERRADO POR MÊS DE BANCO DE DADOS

select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario
where solicitacao.ENCERROU_USUARIO_ID = usuario.id
  and usuario.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID in (select id from helpdesk.classe where upper(descricao) like '%BANCO%' or upper(descricao) like '%ORACLE%'  )
  and DATA_ENCERRADO between to_date('01/10/2017','dd/mm/yyyy') and to_date('31/12/2017 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY') 
order by mes;


--CHAMADOS ENCERRADO POR MÊS POR ANALISTA DE BANCO DE DADOS

col analista format a40
set lines 200 pagesize 80
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, usuario.nome analista, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario
where solicitacao.ENCERROU_USUARIO_ID = usuario.id
  and usuario.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID in (select id from helpdesk.classe where upper(descricao) like '%BANCO%' or upper(descricao) like '%ORACLE%'  )
  and DATA_ENCERRADO between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/12/2018 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), usuario.nome 
order by mes, analista;


---

--CHAMADOS ENCERRADO POR MÊS POR ANALISTA COM USUÁRIO CRIADOR DA TAREFA

col criador_tarefa format a35
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, criador.nome criador_tarefa,atendente.nome analista, classe.descricao, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario atendente, helpdesk.classe, helpdesk.usuario criador
where solicitacao.ENCERROU_USUARIO_ID = atendente.id
	and criador.id=solicitacao.CRIOU_USUARIO_ID
  and atendente.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID = classe.id
  and DATA_ENCERRADO between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/01/2018 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), criador.nome, atendente.nome , classe.descricao
order by mes, analista;

--CHAMADOS ENCERRADO POR MÊS POR ANALISTA CRIADOS PELAS ESTAGIÁRIAS

col criador_tarefa format a35
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, criador.nome criador_tarefa,atendente.nome analista, classe.descricao, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario atendente, helpdesk.classe, helpdesk.usuario criador
where solicitacao.ENCERROU_USUARIO_ID = atendente.id
	and criador.id=solicitacao.CRIOU_USUARIO_ID
	and criador.id in (1651,1665) -- 1651 Gabriela Silva / 1665 Luciana Alencar Nishimura	
  and atendente.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID = classe.id
  and DATA_ENCERRADO between to_date('01/10/2017','dd/mm/yyyy') and to_date('31/12/2017 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), criador.nome, atendente.nome , classe.descricao
order by mes, analista;

--RESUMO DO SELECT ACIMA:

col criador_tarefa format a35
col analista format a35
col finalizou format a35
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, criador.nome criador_tarefa,atendente.nome analista, finalizador.nome finalizou, 
    count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario atendente, helpdesk.classe, helpdesk.usuario criador, helpdesk.usuario finalizador
where solicitacao.ENCERROU_USUARIO_ID = atendente.id
	and criador.id=solicitacao.CRIOU_USUARIO_ID
  and finalizador.id=solicitacao.ENCERROU_USUARIO_ID
	and criador.id in (1651,1665) -- 1651 Gabriela Silva / 1665 Luciana Alencar Nishimura	
  and atendente.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID = classe.id
  and DATA_ENCERRADO between to_date('01/11/2017','dd/mm/yyyy') and to_date('31/12/2017 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), criador.nome, atendente.nome,finalizador.nome
order by mes, analista;


--TAREFAS POR ANALISTA
select usuario.nome analista, count(tarefa.id) quant
 from helpdesk.usuario, helpdesk.tarefa, helpdesk.filial
where usuario.id = tarefa.usuario_executante_id
  AND usuario.FILIAL_ID = FILIAL.ID
  AND filial.EMPRESA_ID = 1
  AND usuario.nome != 'Agente automático N1'
  AND tarefa.DATA_fim between to_date('01/04/2018','dd/mm/yyyy') and LAST_DAY(to_date('26/04/2018','dd/mm/yyyy'))
group by usuario.nome 
order by analista;

======================================
[18:29, 20/10/2017] Bruno Teruya: Chamados fechados por analista;



select table_name from dba_tables where owner='HELPDESK';

--ANALISTAS N3 INFRA:
select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63;



select distinct sol.CLASSE_FINAL_ID, clas.descricao from helpdesk.solicitacao sol, helpdesk.classe clas where sol.CLASSE_FINAL_ID=clas.id

--CATALOGOS DE BANCO
select id from helpdesk.classe where upper(descricao) like '%BANCO%' or upper(descricao) like '%ORACLE%';

--=================================================================================================================================
--=================================================================================================================================
--=================================================================================================================================
--=================================================  FECHAMENTOS GD ===============================================================
--=================================================================================================================================
--=================================================================================================================================
--=================================================================================================================================

-- TODOS: Planilha de operação, dias úteis de cada mês, total de horas de execução dividido pelos dias úteis.


--RAFAEL - Chamados de análise de desempenho
col analista format a40
col descricao format a40
set lines 200 pagesize 80
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, usuario.nome analista, cat.descricao, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario, helpdesk.cat_servico cat
where solicitacao.ENCERROU_USUARIO_ID = usuario.id
  and usuario.id in (select usu.id
      from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
      where usu.situacao='A'
      and usu.filial_id=1
      and usu.filial_id=fil.id
      and usu.id=gusu.usuario_id
      and gusu.grupo_id=gru.id
      and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID = 170
  and cat.classe_id=solicitacao.CLASSE_FINAL_ID
  and cat.id=1461
  and DATA_ENCERRADO between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/12/2018 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), usuario.nome ,cat.descricao
order by mes, analista;

--GUSTAVO E Juliano - Chamados de hardware e projetos
--Avaliar projetos de instalação de equipamentos e em quais o Juliano e o Gustavo agiram

--Contabilizar atividades do Andrey comparadas as atividades do Gustavo e Juliano
--Avaliar atividades de pré-venda do Andrey e quantas atividades o Juliano e Gustavo foram envolvidos

--GABRIELA
--Avaliar redmine, contagem de tempo no ano todo por mês e quais projetos (Tempo Gabriela - Por projeto - Este ano)
--Avaliar chamados atendidos pela gabriela, em quais clientes
col analista format a20
col descricao format a60
set lines 200 pagesize 80
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, usuario.nome analista, fil.nome empresa, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario, helpdesk.filial fil
where usuario.id in (select usu.id
        from helpdesk.usuario usu where nome ='Gabriela Silva')
  and solicitacao.ENCERROU_USUARIO_ID = usuario.id
  and solicitacao.filial_id=fil.id
  and usuario.id=solicitacao.ENCERROU_USUARIO_ID
  and DATA_ENCERRADO between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/12/2018 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), usuario.nome , fil.nome
order by mes, analista;


--RAFAEL BISSI- Chamados não relacionados a banco
select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, usuario.nome analista, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario
where solicitacao.ENCERROU_USUARIO_ID = usuario.id
  and usuario.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID <> 170
  and DATA_ENCERRADO between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/12/2018 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), usuario.nome 
order by mes, analista;

--LEONARDO

select to_char(DATA_ENCERRADO, 'MM/YYYY') mes, usuario.nome analista, count(solicitacao.id) quant
  from helpdesk.solicitacao, helpdesk.usuario
where solicitacao.ENCERROU_USUARIO_ID = usuario.id
  and usuario.id in (select usu.id
from helpdesk.usuario usu, helpdesk.filial fil, helpdesk.grupo gru, helpdesk.grupo_usuario gusu
where usu.situacao='A'
and usu.filial_id=1
and usu.filial_id=fil.id
and usu.id=gusu.usuario_id
and gusu.grupo_id=gru.id
and gru.id=63  )
  and solicitacao.CLASSE_FINAL_ID in (select id from helpdesk.classe where upper(descricao) like '%BANCO%' or upper(descricao) like '%ORACLE%'  )
  and DATA_ENCERRADO between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/12/2018 23:59:59','dd/mm/yyyy hh24:mi:ss')
group by to_char(DATA_ENCERRADO, 'MM/YYYY'), usuario.nome 
order by mes, analista;

--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES
--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES
--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES--TESTES

--orig
SELECT NOME, HORAS+TRUNC((MINUTOS/60)) HORAS,
CASE WHEN MINUTOS >= 60 THEN MINUTOS-(TRUNC((MINUTOS/60))*60) ELSE MINUTOS END MINUTOS
 FROM (
SELECT NOME, SUM(EXTRACT (HOUR FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) HORAS,
      SUM(EXTRACT (MINUTE FROM (DATA_FIM-DATA_INICIO) DAY TO SECOND)) MINUTOS
 FROM ( 
SELECT USUARIO.NOME, et.data_inicio di, et.data_fim df,
      CASE WHEN (ET.DATA_INICIO < TRUNC(SYSDATE)) THEN TRUNC(SYSDATE) ELSE ET.DATA_INICIO END DATA_INICIO,
      CASE WHEN (ET.DATA_FIM IS NULL or et.DATA_FIM > SYSDATE) THEN SYSDATE ELSE ET.DATA_FIM END DATA_FIM
 FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL
WHERE ET.TAREFA_ID = TAREFA.ID
  AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
  AND USUARIO.FILIAL_ID = FILIAL.ID
  AND FILIAL.EMPRESA_ID = 1
  AND (ET.DATA_INICIO >= TRUNC(SYSDATE)
       OR ET.DATA_FIM >= TRUNC(SYSDATE)
       OR ET.DATA_FIM IS NULL)
) GROUP BY NOME
)


--tarefas
SELECT USUARIO.NOME, et.data_inicio di, et.data_fim df,
  CASE WHEN (ET.DATA_INICIO < TRUNC(DIAS.DIA)) THEN TRUNC(DIAS.DIA) ELSE ET.DATA_INICIO END DATA_INICIO,
  CASE WHEN (ET.DATA_FIM IS NULL or et.DATA_FIM > to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS'))
  THEN to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') ELSE ET.DATA_FIM END DATA_FIM
FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL,
  (SELECT data_inicial + LEVEL - 1 dia
    FROM (SELECT TO_DATE('02/06/2017', 'DD/MM/YYYY') data_inicial FROM dual)
      CONNECT BY LEVEL <= TO_DATE('10/06/2017', 'DD/MM/YYYY') - TO_DATE('02/06/2017', 'DD/MM/YYYY') + 1) dias
    WHERE ET.TAREFA_ID = TAREFA.ID
      AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
      AND USUARIO.FILIAL_ID = FILIAL.ID
      AND FILIAL.EMPRESA_ID = 1
      AND TRUNC(DIAS.DIA) BETWEEN TRUNC(ET.DATA_INICIO) AND TRUNC(NVL(ET.DATA_FIM,SYSDATE))
      AND TRUNC(et.DATA_FIM)>trunc(et.data_inicio)
ORDER BY NOME, DIAS.DIA;




SELECT TAREFA.ID,USUARIO.NOME, et.data_inicio di, et.data_fim df,
          CASE WHEN (ET.DATA_INICIO < TRUNC(DIAS.DIA)) THEN TRUNC(DIAS.DIA) ELSE ET.DATA_INICIO END DATA_INICIO,
          CASE WHEN (ET.DATA_FIM IS NULL or et.DATA_FIM > to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS'))
          THEN to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') ELSE ET.DATA_FIM END DATA_FIM
        FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL,helpdesk.grupo gru, helpdesk.grupo_usuario gusu,
          (SELECT data_inicial + LEVEL - 1 dia
            FROM (SELECT TO_DATE('08/12/2017', 'DD/MM/YYYY') data_inicial FROM dual)
              CONNECT BY LEVEL <= TO_DATE('21/12/2017', 'DD/MM/YYYY') - TO_DATE('01/12/2017', 'DD/MM/YYYY') + 1) dias
            WHERE ET.TAREFA_ID = TAREFA.ID
              AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
              AND USUARIO.FILIAL_ID = FILIAL.ID
              AND FILIAL.EMPRESA_ID = 1
              AND TRUNC(DIAS.DIA) BETWEEN TRUNC(ET.DATA_INICIO) AND TRUNC(NVL(ET.DATA_FIM,SYSDATE))
              and USUARIO.ID=gusu.usuario_id
              and gusu.grupo_id=gru.id
              and gru.id=63
              and usuario.nome like 'Raf%' 
order by 5



--IDENTIFICANDO O CHAMADO
alter session set nls_date_format='DD/MM/YYYY hh24:mi:ss';
SELECT ET.TAREFA_ID,USUARIO.NOME, et.data_inicio di, et.data_fim df,
          CASE WHEN (ET.DATA_INICIO < TRUNC(DIAS.DIA)) THEN TRUNC(DIAS.DIA) ELSE ET.DATA_INICIO END DATA_INICIO,
          CASE WHEN (et.DATA_FIM > to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS'))
            THEN to_DATE(TO_CHAR(DIAS.DIA,'DD/MM/YYYY')||' 23:59:59','DD/MM/YYYY HH24:MI:SS') ELSE NVL(ET.DATA_FIM,SYSDATE) END DATA_FIM
        FROM HELPDESK.EXECUCAO_TAREFA ET, HELPDESK.TAREFA, HELPDESK.USUARIO, HELPDESK.FILIAL,helpdesk.grupo gru, helpdesk.grupo_usuario gusu,
          (SELECT data_inicial + LEVEL - 1 dia
            FROM (SELECT TO_DATE('&&data_inicial', 'DD/MM/YYYY') data_inicial FROM dual)
              CONNECT BY LEVEL <= TO_DATE('&data_final', 'DD/MM/YYYY') - TO_DATE('&&data_inicial', 'DD/MM/YYYY') + 1) dias
            WHERE ET.TAREFA_ID = TAREFA.ID
              AND TAREFA.USUARIO_EXECUTANTE_ID = USUARIO.ID
              AND USUARIO.FILIAL_ID = FILIAL.ID
              AND FILIAL.EMPRESA_ID = 1
              AND TRUNC(DIAS.DIA) BETWEEN TRUNC(ET.DATA_INICIO) AND TRUNC(NVL(ET.DATA_FIM,SYSDATE))
              and USUARIO.ID=gusu.usuario_id
              and gusu.grupo_id=gru.id
              and gru.id=63
              and TAREFA.situacao not in ('S')
              and usuario.nome like 'Gus%' 



