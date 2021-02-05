
CREATE TABLESPACE ACADEMICO_BLOB_NEW datafile '+DGDATA/dbass/academico_blob_new001.dbf'
size 1000M AUTOEXTEND ON NEXT 200M MAXSIZE 5000M
FORCE LOGGING;

CREATE TABLESPACE ACADEMICO datafile '/u01/oradata/orahom/academico001.dbf'
size 8000M AUTOEXTEND ON NEXT 200M MAXSIZE 10000M
FORCE LOGGING;

alter tablespace ACADEMICO add datafile '/u01/oradata/orahom/academico002.dbf'
size 10000M AUTOEXTEND
alter tablespace ACADEMICO add datafile '/u01/oradata/orahom/academico003.dbf'
size 5000M AUTOEXTEND
alter tablespace ACADEMICO add datafile '/u01/oradata/orahom/academico004.dbf'
size 5000M AUTOEXTEND
alter tablespace ACADEMICO add datafile '/u01/oradata/orahom/academico005.dbf'
size 5000M AUTOEXTEND

CREATE TABLESPACE ACADEMICO_I datafile '/u01/oradata/orahom/academico_i001.dbf'
size 2000M AUTOEXTEND ON NEXT 200M MAXSIZE 5000M
FORCE LOGGING;





CREATE TABLESPACE ACADEMICO_OLIMPO datafile '/u01/oradata/orahom/academico_olimpo001.dbf'
size 2000M AUTOEXTEND ON NEXT 200M MAXSIZE 5000M
FORCE LOGGING

CREATE TABLESPACE ACADEMICO_OLIMPO_I datafile '/u01/oradata/orahom/academico_olimpo_i001.dbf'
size 2000M AUTOEXTEND ON NEXT 200M MAXSIZE 5000M
FORCE LOGGING;


CREATE TABLESPACE TBS_TOTVS datafile '/u01/oradata/cdbhom/pdbdba/tbs_totvs01.dbf'
size 2000M AUTOEXTEND ON NEXT 200M MAXSIZE 5000M
FORCE LOGGING;

alter tablespace TBS_TOTVS add datafile '/u01/oradata/cdbhom/pdbdba/tbs_totvs02.dbf'
size 2000M AUTOEXTEND ON NEXT 200M MAXSIZE 5000M;