-- VALIDAR SERVIDOR
SELECT NOME,CPF,NOME_MAE,TIPO_MATRICULA,MATRICULA FROM SERVIDOR WHERE MATRICULA = &MATRICULA

--  VALIDAR ESTAGIARIO
SELECT NOME,DATA_NASCIMENTO,CPF,NOME_MAE,TIPO_MATRICULA,MATRICULA FROM ESTAGIARIO WHERE MATRICULA = &MATRICULA

-- VALIDAR TERCEIRO
SELECT NOME,DATA_NASCIMENTO,INDICADOR_ATIVO,CPF,NOME_MAE,TIPO_COLABORADOR FROM COLABORADOR WHERE CPF = &CPF

-- VALIDAR O CADASTRO DO USAURIO 
@vud

-- RECRIAR USUARIO
@CRIA_USUARIO

-- RESETAR SENHA
@zera_senha


-- FALTA DE DADOS
Os dados informados no momento do auto cadastramento estão incorretos, favor entrar em contato com a GESEG para regularizar o seu cadastro. 
Favor aguardar um dia para pedir novo reset de senha para que as informações sejam atualizadas no LDAP.

-- DEMISSÃO
A senha do usuário não pode ser redefinida, porque de acordo com o cadastro do sistema de RH ele se encontra desligado do TJMG (data de dispensa: <>). 
Se não for este o caso, a Sra. Cristina precisa primeiro entrar em contato com o RH para regularizar sua situação funcional e depois abrir novo chamado solicitando a revogação de senha. 

-- TROCA DE SENHA
Sua senha foi redefinida, portanto seu usuário e senha são iguais:  

Usuário = <matrícula do usuário> 
Senha = <matrícula do usuário> 
(sempre com a letra inicial minúscula).    

Após o login na intranet, alterar sua senha na opção menu PESSOAL -> ALTERAR SENHA. 