NETBACKUP - Restore de bancos via RMAN

https://apps.na.collabserv.com/wikis/home?lang=pt-br#!/wiki/W833354f7d423_420c_9722_aa43b7854c4c/page/NETBACKUP%20-%20Restore%20de%20bancos%20via%20RMAN



-- Exemplos extraídos dos testes realizado na Agrodanieli



---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- QUALITOR --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------

-- LISTAR
/usr/openv/netbackup/bin/bplist -S nbu-master -C oracleprod -t 4 -l -k ORACLE_RMAN_QUALITOR -R /

-- LISTAR COM START_DATE
/usr/openv/netbackup/bin/bplist -S nbu-master -C oracleprod -t 4 -l -s 09/06/2019 -k ORACLE_RMAN_QUALITOR -R /



-- GARANTIR QUE ESTA NA INSTANCIA CORRETA
. oraenv
qualitor


-- RESTORE SPFILE
-- SEGUIR O MESMO PROCESSO QUE VOCÊ FARIA SE ESTIVESSE NO DISCO, INICIANDO O RMAN PARA RECUPERAÇÃO DE SPFILE COM INSTANCIA DUMMY
-- RESTAURAR O SPFILE, EXEMPLO:
rman target /
run {
allocate channel c1 type 'sbt_tape';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_QUALITOR';
restore spfile from 'c-555362313-20190906-1d';
release channel c1;
}

-- INICIAR INSTÂNCIA EM NOMOUNT
rman target /
startup force nomount;


-- RESTAURAR O CONTROLFILE PARA LOCAL ALTERNATIVO
rman target /
run {
allocate channel c1 type 'sbt_tape';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_QUALITOR';
restore controlfile to '/tmp/cntrl_QUALITOR.bak' from 'c-555362313-20190906-1b';
release channel c1;
}

-- CLONAR O CONTROLFILE PARA OS LOCAIS CORRETOS APONTADOS NO SPFILE
rman target /
run {
replicate controlfile from '/tmp/cntrl_QUALITOR.bak';
} 


-- MONTAR BASE
alter database mount;

-- REALIZAR O RESTORE DO BACKUP
RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE';
ALLOCATE CHANNEL ch01 TYPE 'SBT_TAPE';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_QUALITOR';
RESTORE DATABASE;
RECOVER DATABASE;
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
} 


-- OPEN RESETLOGS

SQL> alter database open resetlogs;

Database altered.



---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- SAG --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------


-- LISTAR
/usr/openv/netbackup/bin/bplist -S nbu-master -C oracleprod -t 4 -l -k ORACLE_RMAN_SAG -R /

-- LISTAR COM START_DATE
/usr/openv/netbackup/bin/bplist -S nbu-master -C oracleprod -t 4 -l -s 09/06/2019 -k ORACLE_RMAN_SAG -R /



-- GARANTIR QUE ESTA NA INSTANCIA CORRETA
. oraenv
sag


-- RESTORE SPFILE
-- SEGUIR O MESMO PROCESSO QUE VOCÊ FARIA SE ESTIVESSE NO DISCO, INICIANDO O RMAN PARA RECUPERAÇÃO DE SPFILE COM INSTANCIA DUMMY
-- RESTAURAR O SPFILE, EXEMPLO:
rman target /
run {
allocate channel c1 type 'sbt_tape';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_SAG';
restore spfile from 'c-2597975968-20190906-21';
release channel c1;
}

-- INICIAR INSTÂNCIA EM NOMOUNT
rman target /
startup force nomount;


-- RESTAURAR O CONTROLFILE PARA LOCAL ALTERNATIVO
rman target /
run {
allocate channel c1 type 'sbt_tape';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_SAG';
restore controlfile to '/tmp/cntrl_SAG.bak' from 'c-2597975968-20190906-21';
release channel c1;
}

-- CLONAR O CONTROLFILE PARA OS LOCAIS CORRETOS APONTADOS NO SPFILE
rman target /
run {
replicate controlfile from '/tmp/cntrl_SAG.bak';
} 


-- MONTAR BASE
alter database mount;

-- REALIZAR O RESTORE DO BACKUP
RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE';
ALLOCATE CHANNEL ch01 TYPE 'SBT_TAPE';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_SAG';
RESTORE DATABASE;
RECOVER DATABASE;
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
} 


-- OPEN RESETLOGS

SQL> alter database open resetlogs;

Database altered.


------------------------------------------------
-- PROCEDIMENTO PARA CATALOGAR NOVOS ARCHIVES --
------------------------------------------------

-- É necessário configurar um canal SBT_TAPE padrão:
rman target /
CONFIGURE CHANNEL DEVICE TYPE 'SBT_TAPE' PARMS 'ENV=(NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_SAG, SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64)';

-- LISTE OS BACKUPS E ANOTE OS ARQUIVOS NECESSÁRIOS, EXECUTE:
catalog device type 'sbt_tape' backuppiece 'ARCH_SAG_20190906_3532_1018281639';
catalog device type 'sbt_tape' backuppiece 'ARCH_SAG_20190906_3528_1018279842';
catalog device type 'sbt_tape' backuppiece 'ARCH_SAG_20190906_3524_1018278039';
...
...

-- REALIZE O RECOVER:
RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE';
send 'NB_ORA_SERV=nbu-master, NB_ORA_CLIENT=oracleprod, NB_ORA_POLICY=ORACLE_RMAN_SAG';
RECOVER DATABASE;
RELEASE CHANNEL ch00;
} 











------------------------- OPATCH DO TIMEZONE -- ERRO AO ABRIR BANCO Failed to find timezone data file # 32 (DST_4)



[oracle@oracleqa 28125601]$ opatch prereq CheckConflictAgainstOHWithDetail -ph ./
Oracle Interim Patch Installer version 11.2.0.3.4
Copyright (c) 2012, Oracle Corporation.  All rights reserved.

PREREQ session

Oracle Home       : /u01/app/oracle/product/11.2.0/dbhome_1
Central Inventory : /u01/app/oraInventory
   from           : /u01/app/oracle/product/11.2.0/dbhome_1/oraInst.loc
OPatch version    : 11.2.0.3.4
OUI version       : 11.2.0.4.0
Log file location : /u01/app/oracle/product/11.2.0/dbhome_1/cfgtoollogs/opatch/opatch2019-09-06_16-36-51PM_1.log

Invoking prereq "checkconflictagainstohwithdetail"

Prereq "checkConflictAgainstOHWithDetail" passed.

OPatch succeeded.
[oracle@oracleqa 28125601]$ opatch apply
Oracle Interim Patch Installer version 11.2.0.3.4
Copyright (c) 2012, Oracle Corporation.  All rights reserved.


Oracle Home       : /u01/app/oracle/product/11.2.0/dbhome_1
Central Inventory : /u01/app/oraInventory
   from           : /u01/app/oracle/product/11.2.0/dbhome_1/oraInst.loc
OPatch version    : 11.2.0.3.4
OUI version       : 11.2.0.4.0
Log file location : /u01/app/oracle/product/11.2.0/dbhome_1/cfgtoollogs/opatch/28125601_Sep_06_2019_16_37_00/apply2019-09-06_16-37-00PM_1.log

Applying interim patch '28125601' to OH '/u01/app/oracle/product/11.2.0/dbhome_1'
Verifying environment and performing prerequisite checks...
Patch 28125601: Optional component(s) missing : [ oracle.oracore.rsf.core, 11.2.0.4.0 ]
All checks passed.
Backing up files...

Patching component oracle.oracore.rsf, 11.2.0.4.0...

Verifying the update...
Patch 28125601 successfully applied
Log file location: /u01/app/oracle/product/11.2.0/dbhome_1/cfgtoollogs/opatch/28125601_Sep_06_2019_16_37_00/apply2019-09-06_16-37-00PM_1.log

OPatch succeeded.