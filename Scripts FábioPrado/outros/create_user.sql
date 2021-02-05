
create user U_MARCELO               identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_ALEXANDRE_BAEHR       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_ALEX_SANTANNA         identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_AUGUSTO_LENZI         identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_CLOVES_MACHADO        identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_DBA_NUTEC             identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_DECIO_LEHMKUHL        identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_DOUGLAS_DALPIAZ       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_EMMERSON_BECKER       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_EVANDRO_AUGUSTO       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_FABRICIO_VARGAS       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_GILMAR_RADUENZ        identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_GUILHERME_SCHIOCHETTI identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_JEFFERSON_SILVA       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_LAERCIO_METZNER       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_MARCOS_ALBERTON       identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_RAFAEL_MACIEL         identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_RAFAEL_MOSER          identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;
create user U_RODRIGO_CASALI        identified by senhapadraooracle#2016 profile FORCE_PASSWORD password EXPIRE;

create user U_HERMENEGILDO_MARIN identified by senhapadraooracle#2017 profile FORCE_PASSWORD password EXPIRE;
grant R_CONSULTA_DBASS to U_HERMENEGILDO_MARIN;

grant R_CONSULTA_DBASS to U_ALEXANDRE_BAEHR;
grant R_CONSULTA_DBASS to U_ALEX_SANTANNA  ;      
grant R_CONSULTA_DBASS to U_AUGUSTO_LENZI   ;     
grant R_CONSULTA_DBASS to U_CLOVES_MACHADO   ;    
grant R_CONSULTA_DBASS to U_DBA_NUTEC         ;   
grant R_CONSULTA_DBASS to U_DECIO_LEHMKUHL     ;  
grant R_CONSULTA_DBASS to U_DOUGLAS_DALPIAZ     ; 
grant R_CONSULTA_DBASS to U_EMMERSON_BECKER      ;
grant R_CONSULTA_DBASS to U_EVANDRO_AUGUSTO      ;
grant R_CONSULTA_DBASS to U_FABRICIO_VARGAS      ;
grant R_CONSULTA_DBASS to U_GILMAR_RADUENZ       ;
grant R_CONSULTA_DBASS to U_GUILHERME_SCHIOCHETTI;
grant R_CONSULTA_DBASS to U_JEFFERSON_SILVA      ;
grant R_CONSULTA_DBASS to U_LAERCIO_METZNER      ;
grant R_CONSULTA_DBASS to U_MARCOS_ALBERTON      ;
grant R_CONSULTA_DBASS to U_RAFAEL_MACIEL        ;
grant R_CONSULTA_DBASS to U_RAFAEL_MOSER         ;
grant R_CONSULTA_DBASS to U_RODRIGO_CASALI       ;



create user RZGU52_HIST identified by totvs2017
default tablespace TS_DATA_RZGU52_HIST;

alter user RZGU52_HIST quota unlimited on TS_DATA_RZGU52_HIST;

GRANT R_USER_DEV TO U_JEFFERSON_SILVA;


create user U_REGINALDO_SILVA identified by senhapadraooracle#2017
profile FORCE_PASSWORD
password EXPIRE;
grant R_CONSULTA_DBASS to U_REGINALDO_SILVA;


GRANT R_USER_DEV TO U_RODRIGO_CASALI

alter user U_REGINALDO_SILVA identified by senhapadraooracle#2017 password EXPIRE;

Laércio Metzner