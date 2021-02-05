-- ver estatisticas relacionadas a servicos
select  service_name,
        stat_name,
       trunc((value / 1000000),2)
from    v$service_stats
order by 3 desc, 1, 2