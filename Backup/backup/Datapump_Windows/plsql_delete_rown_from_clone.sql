DECLARE
	table_name varchar2(20);
BEGIN
	table_name := 'scott.MYTABLESCOTT';
	EXECUTE IMMEDIATE 'DELETE FROM ' || table_name || ' WHERE id = 1;';
EXCEPTION
	WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;

--create table novo_20190215 (id number(5) primary key, name varchar2(50) not null); 


--insert into novo_20190215 values (1, 'tesntando para clone 1');
--insert into novo_20190215 values (2, 'tesntando para clone 2');
--insert into novo_20190215 values (3, 'tesntando para clone 3');
--insert into novo_20190215 values (4, 'tesntando para clone 4');
--insert into novo_20190215 values (5, 'tesntando para clone 5');
--insert into novo_20190215 values (6, 'tesntando para clone 6');