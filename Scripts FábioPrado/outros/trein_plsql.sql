
-- criar tabela marca

create table marca (
	id_marca number(7) constraint pk_marca primary key,
	nome_marca varchar2(12) not null unique,
	ativo char(1) not null,
	constraint marca_ativo check(ativo in ('S','N','s','n'))
);


-- CRIAR SEQUENCE

create sequence seq_id_marca
	start with 100
	increment by 10
	nocycle
	nocache
	;
	
-- CRIAR TABELA	MODELO

create table modelo(
	id_marca number(7) not null,
	id_modelo number(7) not null,
	nome_modelo varchar2(120) not null unique,
	ativo char(1) 
		constraint modelo_ativo check(ativo in ('S','N','s','n')),
	constraint fk_tbl_marca foreign key (id_marca) references marca(id_marca),
	constraint pk_modelo primary key (id_marca, id_modelo)
);

-- criar tabela versao

create table versao(
	id_marca number(7) not null,
	id_modelo number(7) not null,
	id_versao number(7) not null,
	nome_versao varchar2(120) not null unique,
	ativo char(1) 
	constraint versao_ativo check(ativo in ('S','N','s','n')),
	constraint fk_tbl_marca_v foreign key (id_marca) references marca(id_marca),
	constraint fk_tbl_modelo foreign key (id_marca,id_modelo) 
			references modelo (id_marca,id_modelo),
	constraint pk_versao primary key (id_marca, id_modelo, id_versao)
);

-- inserir dados na tabela marca

insert into marca (id_marca, nome_marca, ativo) 
	   values (seq_id_marca.nextval, 'Ford', 'N');
	   
	   
-- inserir dados na tabela modelo
	   
insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values (110, 1, 'Corsa', 'N');	   
insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values (110, 2, 'Meriva', 'N');
insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values (110, 3, 'Cobalt', 'N');
insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values (110, 4, 'Monza', 'N');
insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values (110, 5, 'Vectra', 'N');
insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values (110, 6, 'Astra', 'N');


-- criar procedure

create or replace procedure proc_inserir_veiculo(
	par_marca in marca.nome_marca%type,
	par_modelo in modelo.nome_modelo%type
	)
	
is
vcount_marca  number;
vcount_modelo number;
vid_marca     number;
vid_modelo	  number := 0; 

begin
/*inserir marca na tabela marca*/
	select count(*) into vcount_marca from marca 
		where
			nome_marca = par_marca;
			if vcount_marca = 0 then
				select seq_id_marca.nextval into vid_marca from dual;
				insert into marca(id_marca, nome_marca, ativo) 
					values (vid_marca, par_marca, 'N');
					commit;
			else
				select id_marca into vid_marca from marca
					where nome_marca = par_marca;
			end if;
			
/*inserir modelo na tabela modelo*/

	select count(*) into vcount_modelo from modelo where	
		id_marca = vid_marca and nome_modelo = par_modelo;
	if vcount_modelo = 0 then
	select max(id_modelo) into vid_modelo from modelo where
		id_marca = vid_marca;
	vid_modelo := nvl(vid_modelo, 0) +1;
	insert into modelo (id_marca, id_modelo, nome_modelo, ativo) values
		(vid_marca, vid_modelo, par_modelo, 'N');
		commit;
	else
		select id_modelo into vid_modelo from modelo where	
			nome_modelo = par_modelo;
	end if;
end proc_inserir_veiculo;
/





















