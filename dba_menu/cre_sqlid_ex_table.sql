create table system.sql_id_exceptions
(
sql_id varchar2(13),
date_added date,
added_by varchar2(20),
comments varchar2(1000)
)
tablespace tools
/

create index system.sql_id_exceptions_uk1 on system.sql_id_exceptions(sql_id) tablespace tools
/

grant select on system.sql_id_exceptions to dbsnmp
/
