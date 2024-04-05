-- LISTAR CONTEÚDO DIRETÓRIO
select * from table(RDSADMIN.RDS_FILE_UTIL.LISTDIR('DATA_PUMP_DIR')) order by mtime;

-- LER CONTEÚDO ARQUIVO (use spool para salvar local)
SELECT text FROM table(rdsadmin.rds_file_util.read_text_file('DATA_PUMP_DIR','export_maxy_20180801_0.log'));

-- APAGAR ARQUIVO
EXEC UTL_FILE.FREMOVE (location => 'DATA_PUMP_DIR', filename => 'maxy.dmp');


-- IMPORT VIA DATAPUMP
DECLARE
hdnl NUMBER;
BEGIN
hdnl := DBMS_DATAPUMP.OPEN( operation => 'IMPORT', job_mode => 'SCHEMA', job_name=>'maxysxml_20180725_0');
DBMS_DATAPUMP.ADD_FILE( handle => hdnl, filename => 'maxysxml_20180724_0.dmp', directory => 'DATA_PUMP_DIR', filetype => dbms_datapump.ku$_file_type_dump_file);
DBMS_DATAPUMP.ADD_FILE( handle => hdnl, filename => 'maxysxml_20180724_0.log', directory => 'DATA_PUMP_DIR', filetype => dbms_datapump.ku$_file_type_log_file);
DBMS_DATAPUMP.METADATA_FILTER(hdnl,'SCHEMA_EXPR','IN (''MAXYSXML'')');
DBMS_DATAPUMP.START_JOB(hdnl);
END;
/  


-- EXPORT VIA DATAPUMP
DECLARE
hdnl NUMBER;
BEGIN
hdnl := DBMS_DATAPUMP.OPEN( operation => 'EXPORT', job_mode => 'SCHEMA', job_name=>'maxysxml_20180801_0');
DBMS_DATAPUMP.ADD_FILE( handle => hdnl, filename => 'export_maxy_20180801_0.dmp', directory => 'DATA_PUMP_DIR', filetype => dbms_datapump.ku$_file_type_dump_file);
DBMS_DATAPUMP.ADD_FILE( handle => hdnl, filename => 'export_maxy_20180801_0.log', directory => 'DATA_PUMP_DIR', filetype => dbms_datapump.ku$_file_type_log_file);
DBMS_DATAPUMP.METADATA_FILTER(hdnl,'SCHEMA_EXPR','IN (''PRD_IAU'',''PRD_IAU_APPEND'',''PRD_IAU_VIEWER'',''PRD_MDS'',''PRD_OPSS'',''PRD_STB'',''PRD_UMS'',''PRD_WLS'',''PRD_WLS_RUNTIME'')');
DBMS_DATAPUMP.START_JOB(hdnl);
END;
/


-- CÓPIA DE ARQUIVO VIA DB_LINK PARA RDS
BEGIN
DBMS_FILE_TRANSFER.PUT_FILE(
source_directory_object       => 'DATAPUMP',
source_file_name              => 'maxicon_20180724.dmp',
destination_directory_object  => 'DATA_PUMP_DIR',
destination_file_name         => 'maxicon_20180724.dmp', 
destination_database          => 'TO_RDS' 
);
END;
/ 


-- CÓPIA DE ARQUIVO VIA DB_LINK DA RDS
BEGIN
DBMS_FILE_TRANSFER.GET_FILE(
source_directory_object       => 'DATA_PUMP_DIR',
source_file_name              => 'export_maxy_20180801_0.dmp',
destination_directory_object  => 'DATAPUMP',
destination_file_name         => 'export_maxy_20180801_0.dmp', 
source_database   	          => 'TO_RDS' 
);
END;
/ 


CREATE PUBLIC DATBASE LINK TO_EC2 CONNECT TO 


PROCEDURE GET_FILE
 Nome do Argumento                  Tipo                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 SOURCE_DIRECTORY_OBJECT        VARCHAR2                IN
 SOURCE_FILE_NAME               VARCHAR2                IN
 SOURCE_DATABASE                VARCHAR2                IN
 DESTINATION_DIRECTORY_OBJECT   VARCHAR2                IN
 DESTINATION_FILE_NAME          VARCHAR2                IN

 PROCEDURE PUT_FILE
 Nome do Argumento                  Tipo                    In/Out Default?
 ------------------------------ ----------------------- ------ --------
 SOURCE_DIRECTORY_OBJECT        VARCHAR2                IN
 SOURCE_FILE_NAME               VARCHAR2                IN
 DESTINATION_DIRECTORY_OBJECT   VARCHAR2                IN
 DESTINATION_FILE_NAME          VARCHAR2                IN
 DESTINATION_DATABASE           VARCHAR2                IN


