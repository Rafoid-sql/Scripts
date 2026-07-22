select * from
(select round(sum(bytes/1024/1024/1024)) used_db_space_gb from dba_segments) ,
(select round(sum(bytes/1024/1024/1024)) allocated_db_space_gb from dba_data_files)
;
