set verify off
COLUMN parameter           FORMAT a37
COLUMN description         FORMAT a30 WORD_WRAPPED
COLUMN "Session VALUE"     FORMAT a10
COLUMN "Instance VALUE"    FORMAT a10
set lines 1000 pages 999
 
SELECT
   a.ksppinm  "Parameter",
   a.ksppdesc "Description",
   b.ksppstvl "Session Value",
   c.ksppstvl "Instance Value"
FROM
   x$ksppi a,
   x$ksppcv b,
   x$ksppsv c
WHERE
   a.indx = b.indx
   AND
   a.indx = c.indx
   AND
   a.ksppinm LIKE '%&1%' escape '/'
;

undefine 1
