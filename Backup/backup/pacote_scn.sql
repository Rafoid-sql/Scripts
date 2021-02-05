  CREATE OR REPLACE PACKAGE "TEIKOBKP"."TK_CLONEDB_DATAPUMP" is

  -- Grants
     -- grant select on v_$instance to teikobkp;
     -- grant select on v_$database to teikobkp;
     -- grant select on gv_$instance to teikobkp;
     -- grant select on dba_objects to teikobkp;
     -- grant create session, create table, create procedure, exp_full_database, imp_full_database to teikobkp;
     -- grant select on DBA_DATA_FILES to TEIKOBKP;
     -- grant select on DBA_FREE_SPACE to TEIKOBKP;
     -- grant select on DBA_SEGMENTS to TEIKOBKP;
     -- grant select on DBA_TABLESPACES to TEIKOBKP;
     -- grant select on DBA_TEMP_FILES to TEIKOBKP;
     -- grant select on V_$TEMP_SPACE_HEADER to TEIKOBKP;
     -- grant select on dba_users to TEIKOBKP;
     -- GRANT READ  ON DIRECTORY data_pump TO teikobkp;
     -- GRANT WRITE ON DIRECTORY data_pump TO teikobkp;


  type TypeDumpFileV is varray(24) of varchar2(2048);

  PROCEDURE TK_DISPARA_BACKUP_POR_OWNER(p_schema     IN VARCHAR2,
                                        p_dump_dir   IN VARCHAR2,
                                        p_dump_file  in varchar2 default null,
                                        p_log_file   in varchar2 default null,
                                        p_file_ctl   in varchar2 default null,
                                        p_degree     in number default null,
                                        p_FileSize   in varchar2 default '5G',
                                        p_Version    in varchar2 default 'COMPATIBLE',
                                        p_Caminhoctl out varchar2 );

  PROCEDURE TK_DISPARA_BACKUP_POR_FULL(p_dump_dir   in varchar2,
                                       p_dump_file  in varchar2 default null,
                                       p_log_file   in varchar2 default null,
                                       p_file_ctl   in varchar2 default null,
                                       p_degree     in number default null,
                                       p_FileSize   in varchar2 default '5G',
                                       p_Version    in varchar2 default 'COMPATIBLE',
                                       p_Caminhoctl out varchar2);


end TK_CLONEDB_DATAPUMP;

/
CREATE OR REPLACE PACKAGE BODY "TEIKOBKP"."TK_CLONEDB_DATAPUMP" is


  function RetornoDumpfileInfo(p_dir  VARCHAR2 DEFAULT 'DATA_PUMP_DIR',
                               p_file VARCHAR2)
    return TK_CLONEDB_DATAPUMP.TypeDumpFileV AS
    v_separator   VARCHAR2(80) := '--------------------------------------' ||
                                  '--------------------------------------';
    v_path        all_directories.directory_path%type := '?';
    v_filetype    NUMBER; -- 0=unknown 1=expdp 2=exp 3=ext
    v_fileversion VARCHAR2(15); -- 0.1=10gR1 1.1=10gR2 (etc.)
    v_info_table  sys.ku$_dumpfile_info; -- PL/SQL table with file info
    var_values TK_CLONEDB_DATAPUMP.TypeDumpFileV := TK_CLONEDB_DATAPUMP.TypeDumpFileV();
    no_file_found EXCEPTION;
    PRAGMA exception_init(no_file_found, -39211);
  BEGIN

    -- Dump file details:
    -- ==================
    -- For Oracle10g Release 2 and higher:
    --    dbms_datapump.KU$_DFHDR_FILE_VERSION        CONSTANT NUMBER := 1;
    --    dbms_datapump.KU$_DFHDR_MASTER_PRESENT      CONSTANT NUMBER := 2;
    --    dbms_datapump.KU$_DFHDR_GUID                CONSTANT NUMBER := 3;
    --    dbms_datapump.KU$_DFHDR_FILE_NUMBER         CONSTANT NUMBER := 4;
    --    dbms_datapump.KU$_DFHDR_CHARSET_ID          CONSTANT NUMBER := 5;
    --    dbms_datapump.KU$_DFHDR_CREATION_DATE       CONSTANT NUMBER := 6;
    --    dbms_datapump.KU$_DFHDR_FLAGS               CONSTANT NUMBER := 7;
    --    dbms_datapump.KU$_DFHDR_JOB_NAME            CONSTANT NUMBER := 8;
    --    dbms_datapump.KU$_DFHDR_PLATFORM            CONSTANT NUMBER := 9;
    --    dbms_datapump.KU$_DFHDR_INSTANCE            CONSTANT NUMBER := 10;
    --    dbms_datapump.KU$_DFHDR_LANGUAGE            CONSTANT NUMBER := 11;
    --    dbms_datapump.KU$_DFHDR_BLOCKSIZE           CONSTANT NUMBER := 12;
    --    dbms_datapump.KU$_DFHDR_DIRPATH             CONSTANT NUMBER := 13;
    --    dbms_datapump.KU$_DFHDR_METADATA_COMPRESSED CONSTANT NUMBER := 14;
    --    dbms_datapump.KU$_DFHDR_DB_VERSION          CONSTANT NUMBER := 15;
    -- For Oracle11gR1:
    --    dbms_datapump.KU$_DFHDR_MASTER_PIECE_COUNT  CONSTANT NUMBER := 16;
    --    dbms_datapump.KU$_DFHDR_MASTER_PIECE_NUMBER CONSTANT NUMBER := 17;
    --    dbms_datapump.KU$_DFHDR_DATA_COMPRESSED     CONSTANT NUMBER := 18;
    --    dbms_datapump.KU$_DFHDR_METADATA_ENCRYPTED  CONSTANT NUMBER := 19;
    --    dbms_datapump.KU$_DFHDR_DATA_ENCRYPTED      CONSTANT NUMBER := 20;
    -- For Oracle11gR2:
    --    dbms_datapump.KU$_DFHDR_COLUMNS_ENCRYPTED   CONSTANT NUMBER := 21;
    --    dbms_datapump.KU$_DFHDR_ENCRIPTION_MODE     CONSTANT NUMBER := 22;
    -- For Oracle12cR1:
    --    dbms_datapump.KU$_DFHDR_COMPRESSION_ALG     CONSTANT NUMBER := 23;

    -- For Oracle10gR2: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 15;
    -- For Oracle11gR1: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 20;
    -- For Oracle11gR2: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 22;
    -- For Oracle12cR1: KU$_DFHDR_MAX_ITEM_CODE       CONSTANT NUMBER := 23;

    -- Show header output info:
    -- ========================

    --dbms_output.put_line(v_separator);
    --dbms_output.put_line('Purpose..: Obtain details about export ' ||
    --      'dumpfile.        Version: 18-DEC-2013');
    --dbms_output.put_line('Required.: RDBMS version: 10.2.0.1.0 or higher');
    --dbms_output.put_line('.          ' ||
    --      'Export dumpfile version: 7.3.4.0.0 or higher');
    --dbms_output.put_line('.          ' ||
    --      'Export Data Pump dumpfile version: 10.1.0.1.0 or higher');
    --dbms_output.put_line('Usage....: ' ||
    --      'execute show_dumfile_info(''DIRECTORY'', ''DUMPFILE'');');
    --dbms_output.put_line('Example..: ' ||
    --      'exec show_dumfile_info(''MY_DIR'', ''expdp_s.dmp'')');
    --dbms_output.put_line(v_separator);
    --dbms_output.put_line('Filename.: ' || p_file);
    --dbms_output.put_line('Directory: ' || p_dir);

    -- Retrieve Export dumpfile details:
    -- =================================

    SELECT directory_path
      INTO v_path
      FROM all_directories
     WHERE directory_name = p_dir
        OR directory_name = UPPER(p_dir);

    dbms_datapump.get_dumpfile_info(filename   => p_file,
                                    directory  => UPPER(p_dir),
                                    info_table => v_info_table,
                                    filetype   => v_filetype);

    var_values.EXTEND(23);
    FOR i in 1 .. 23 LOOP
      BEGIN
        SELECT value
          INTO var_values(i)
          FROM TABLE(v_info_table)
         WHERE item_code = i;
      EXCEPTION
        WHEN OTHERS THEN
          var_values(i) := '';
      END;
    END LOOP;
    IF v_filetype >= 1 THEN
      -- Get characterset name:
      BEGIN
        SELECT var_values(5) || ' (' || nls_charset_name(var_values(5)) || ')'
          INTO var_values(5)
          FROM dual;
      EXCEPTION
        WHEN OTHERS THEN
          null;
      END;
      IF v_filetype = 2 THEN
        SELECT DECODE(var_values(13),
                      '0',
                      '0 (Conventional Path)',
                      '1',
                      '1 (Direct Path)',
                      var_values(13))
          INTO var_values(13)
          FROM dual;
      ELSIF v_filetype = 1 OR v_filetype = 3 THEN
        SELECT SUBSTR(var_values(1), 1, 15) INTO v_fileversion FROM dual;
        SELECT DECODE(var_values(1),
                      '0.1',
                      '0.1 (Oracle10g Release 1: 10.1.0.x)',
                      '1.1',
                      '1.1 (Oracle10g Release 2: 10.2.0.x)',
                      '2.1',
                      '2.1 (Oracle11g Release 1: 11.1.0.x)',
                      '3.1',
                      '3.1 (Oracle11g Release 2: 11.2.0.x)',
                      '4.1',
                      '4.1 (Oracle12c Release 1: 12.1.0.x)',
                      var_values(1))
          INTO var_values(1)
          FROM dual;
        SELECT DECODE(var_values(2),
                      '0',
                      '0 (No)',
                      '1',
                      '1 (Yes)',
                      var_values(2))
          INTO var_values(2)
          FROM dual;
        SELECT DECODE(var_values(14),
                      '0',
                      '0 (No)',
                      '1',
                      '1 (Yes)',
                      var_values(14))
          INTO var_values(14)
          FROM dual;
        SELECT DECODE(var_values(18),
                      '0',
                      '0 (No)',
                      '1',
                      '1 (Yes)',
                      var_values(18))
          INTO var_values(18)
          FROM dual;
        SELECT DECODE(var_values(19),
                      '0',
                      '0 (No)',
                      '1',
                      '1 (Yes)',
                      var_values(19))
          INTO var_values(19)
          FROM dual;
        SELECT DECODE(var_values(20),
                      '0',
                      '0 (No)',
                      '1',
                      '1 (Yes)',
                      var_values(20))
          INTO var_values(20)
          FROM dual;
        SELECT DECODE(var_values(21),
                      '0',
                      '0 (No)',
                      '1',
                      '1 (Yes)',
                      var_values(21))
          INTO var_values(21)
          FROM dual;
        SELECT DECODE(var_values(22),
                      '1',
                      '1 (Unknown)',
                      '2',
                      '2 (None)',
                      '3',
                      '3 (Password)',
                      '4',
                      '4 (Password and Wallet)',
                      '5',
                      '5 (Wallet)',
                      var_values(22))
          INTO var_values(22)
          FROM dual;
        SELECT DECODE(var_values(23),
                      '2',
                      '2 (None)',
                      '3',
                      '3 (Basic)',
                      '4',
                      '4 (Low)',
                      '5',
                      '5 (Medium)',
                      '6',
                      '6 (High)',
                      var_values(23))
          INTO var_values(23)
          FROM dual;
      END IF;
    ELSE
      var_values(24) := 'ERROR....: Not an export dumpfile';
    END IF;
    return var_values;
  EXCEPTION
    WHEN no_data_found THEN
      dbms_output.put_line('Disk Path: ?');
      dbms_output.put_line('Filetype.: ?');
      dbms_output.put_line(v_separator);
      dbms_output.put_line('ERROR....: Directory Object does not exist.');
      dbms_output.put_line(v_separator);
    WHEN no_file_found THEN
      dbms_output.put_line('Disk Path: ' || v_path);
      dbms_output.put_line('Filetype.: ?');
      dbms_output.put_line(v_separator);
      dbms_output.put_line('ERROR....: File does not exist.');
      dbms_output.put_line(v_separator);
  END RetornoDumpfileInfo;

-- Este pacote ÃƒÂ© somente possivel colocar 1 owner por vez.

  PROCEDURE TK_DISPARA_BACKUP_POR_OWNER(p_schema     IN VARCHAR2,
                                        p_dump_dir   IN VARCHAR2,
                                        p_dump_file  in varchar2 default null,
                                        p_log_file   in varchar2 default null,
                                        p_file_ctl   in varchar2 default null,
                                        p_degree     in number default null,
                                        p_FileSize   in varchar2 default '5G',
                                        p_Version    in varchar2 default 'COMPATIBLE',
                                        p_Caminhoctl out varchar2 ) IS
    dp_handle         NUMBER;
    job_status        VARCHAR2(30);
    v_dt              NUMBER;
    v_sch_name        VARCHAR2(30);
    v_filename        VARCHAR2(100);
    v_logname         VARCHAR2(100);
    v_FileControle    VARCHAR2(100);
    v_instance        v$instance.INSTANCE_NAME%type;
    v_Scn             v$database.CURRENT_SCN%type;
    v_DataInicio      varchar2(22) default to_char(sysdate,'dd/mm/yyyy hh24:mi:ss');
    v_DataFim         varchar2(22);
    V_Job_name        varchar2(30);
    v_SelectFileN     varchar2(1000);
    v_SelectOwner     varchar2(1000);
    v_UserCorrente    varchar2(30);
    v_file_name       varchar2(2000);
    v_file_name_x     varchar2(2000);
    v_file_max_size   integer;
    v_OwnerExpdp      varchar2(30);
    v_StatusExpdp     varchar2(1000);
    TYPE cur_typ IS REF CURSOR;
    c                 cur_typ;
    c1                cur_typ;
    c3                cur_typ;
    RetornoDPFiles    TK_CLONEDB_DATAPUMP.TypeDumpFileV := TK_CLONEDB_DATAPUMP.TypeDumpFileV();
    v_guid_id_char    varchar(100);
    v_version         v$instance.version%type;
    v_PonteiroCtl     utl_file.file_type;
    v_dbid            v$database.DBID%type;
    v_nameDb          v$database.NAME%type;
    v_Uk_nameDb       v$database.DB_UNIQUE_NAME%type;
    vContaReg         integer;
    vTpObjeto         varchar2(100);
    vOwnerObjeto      varchar2(100);
    vNmObjeto         varchar2(100);
    vTempUserDefault  dba_users.temporary_tablespace%type;
    v_CaminhoLogExpdp varchar2(2000);
  BEGIN
    select sys_context('userenv', 'current_schema')
      into v_UserCorrente
      from dual;

    select upper(xx.INSTANCE_NAME) || '.', version
      into v_instance, v_version
      from v$instance xx;

    SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'yyyymmddhh24mmss'))
      INTO v_dt
      FROM DUAL;

    select to_char(current_scn) into v_Scn from v$database;

    v_sch_name := 'IN (''' || upper(p_schema) || ''')';

    if p_dump_file is null then
      v_filename := v_instance || '' || p_schema || '%U' || '.' || v_dt ||
                    '.dmp';
    else
      v_filename := p_dump_file;
    end if;

    if p_log_file is null then
      v_logname := v_instance || '' || p_schema || '.' || v_dt || '.log';
    else
      v_logname := p_log_file;
    end if;

    if p_file_ctl is null then
      v_FileControle := v_instance || '' || p_schema || '.' || v_dt ||
                        '.ctl';
    else
      v_FileControle := p_file_ctl;
    end if;

    V_Job_name := 'DP_' || TO_CHAR(sysdate, 'DD_MM_YYYY_HH24_MI_SS');

    dp_handle := DBMS_DATAPUMP.open(operation => 'EXPORT',
                                    job_mode  => 'SCHEMA',
                                    version   => p_Version,
                                    job_name  => V_Job_name);
    dbms_datapump.set_parameter(dp_handle,
                                'CLIENT_COMMAND',
                                'Export (EXPDP) (arquivo de controle ÃƒÂ© ' ||
                                v_FileControle || ') do owner ' ||
                                upper(p_schema) || ' em ' ||
                                to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss'));
    dbms_datapump.set_parameter(dp_handle, 'FLASHBACK_SCN', v_Scn);
    dbms_datapump.set_parameter(dp_handle, 'METRICS', 1);
    -- Keep Master tem que ser 1
    dbms_datapump.set_parameter(dp_handle, 'KEEP_MASTER', 1);
    if p_degree is not null then
      dbms_datapump.set_parallel(handle => dp_handle, degree => p_degree);
    end if;
    -- dump file
    DBMS_DATAPUMP.add_file(handle    => dp_handle,
                           filename  => v_filename,
                           directory => p_dump_dir,
                           filesize  => upper(p_FileSize),
                           filetype  => SYS.DBMS_DATAPUMP.KU$_FILE_TYPE_DUMP_FILE);
    -- log file
    DBMS_DATAPUMP.add_file(handle    => dp_handle,
                           filename  => v_logname,
                           directory => p_dump_dir,
                           filetype  => SYS.DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);
    -- specify schema name
    DBMS_DATAPUMP.metadata_filter(handle => dp_handle,
                                  name   => 'SCHEMA_EXPR',
                                  VALUE  => v_sch_name);
    DBMS_DATAPUMP.start_job(handle => dp_handle);
    DBMS_DATAPUMP.wait_for_job(handle    => dp_handle,
                               job_state => job_status);

    v_DataFim := to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss');

    v_PonteiroCtl := utl_file.fopen(p_dump_dir, v_FileControle, 'W');

    vContaReg := 1;
    -- Pega todos os dump files gerados

    if instr(upper(v_filename),'%U') > 0 then
       v_SelectFileN := 'SELECT completed_bytes,file_name , reverse( substr( reverse(file_name),1, instr(reverse(file_name),''/'')-1)) File_name_x  FROM ' ||
                        V_Job_name || '
                              where USER_FILE_NAME is not null
                              and upper(file_name)  not like upper(''%' ||
                       v_filename || '%'') order by 1';
    else
       v_SelectFileN := 'SELECT completed_bytes,file_name , reverse( substr( reverse(file_name),1, instr(reverse(file_name),''/'')-1)) File_name_x  FROM ' ||
                        V_Job_name || '
                              where USER_FILE_NAME is not null
                              and upper(file_name)  like upper(''%' ||
                       v_filename || '%'') order by 1';
    end if;
    open c for v_SelectFileN;
    loop
      fetch c
        into v_file_max_size, v_file_name, v_file_name_x;
      exit when c%notfound;
      RetornoDPFiles := RetornoDumpfileInfo(p_dir  => p_dump_dir,
                                            p_file => v_file_name_x);

      -- EXPDP_ID_1_1 NM_FILE_DP[X],INTERNAL_DF_VERSION[X],FILE_NUMBER[X],LANG_NAME_CHAR[X],CREATE_DATE_DF[X],TAMANHO_BYTES[X]
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_1_' || vContaReg || ' NM_FILE_DP[' ||
                        v_file_name || '],INTERNAL_DF_VERSION[' ||
                        RetornoDPFiles(1) || '],FILE_NUMBER[' ||
                        RetornoDPFiles(4) || '],LANG_NAME_CHAR[' ||
                        RetornoDPFiles(11) || '],CREATE_DATE_DF[' ||
                        RetornoDPFiles(6) || '],TAMANHO_BYTES[' ||
                        v_file_max_size || ']');
      vContaReg := vContaReg + 1;
    end loop;
    v_guid_id_char := RetornoDPFiles(3);
    close c;

    select DBID, NAME, DB_UNIQUE_NAME
      into v_dbid, v_nameDb, v_Uk_nameDb
      from v$database;

    -- EXPDP_ID_2 DATA_INICIO_EXPDP[01/09/2017 HH24:MI:SS],DATA_FIM_EXPD[01/09/2017 HH24:MI:SS],DBID[XX],NAME:[DBPROD],DB_UNIQUE_NAME[DBPROD]
    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_2 DATA_INICIO_EXPDP[' || v_DataInicio ||
                      '],DATA_FIM_EXPDP[' || v_DataFim || '],DBID[' ||
                      v_dbid || '],NAME[' || v_nameDb ||
                      '],DB_UNIQUE_NAME[' || v_Uk_nameDb || ']');

    --EXPDP_ID_3_1 HOST_NAME[server1]
    --EXPDP_ID_3_2 HOST_NAME[server2]
    vContaReg := 1;
    For nx in (select t.host_name from gv$instance t) loop
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_3_' || vContaReg || ' HOST_NAME[' ||
                        nx.host_name || ']');
      vContaReg := vContaReg + 1;
    end loop;

    -- EXPDP_ID_4_1 TABLESPACE_NAME[DATA],TAMANHO_BYTES[24234]
    -- EXPDP_ID_4_2 TABLESPACE_NAME[DATA],TAMANHO_BYTES[24234]
    -- Somente um owner, relata todos os tablespaces do owner e seus tamanhos em bytes
    vContaReg := 1;
    For nx in (select tablespace_name Tablespace,sum(bytes) Tamanho from dba_segments t
                 where t.owner = upper(p_schema)
                 group by tablespace_name) loop
        utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_4_' || vContaReg || ' TABLESPACE_NAME[' ||
                        nx.tablespace || '],TAMANHO_BYTES[' ||
                        to_char(nx.tamanho) || ']');
        vContaReg := vContaReg + 1;
    end loop;

    --EXPDP_ID_5 GUID_ID:[504B596A98BB73E4E0539B0AA8C02D63]
    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_5 GUID_ID[' || v_guid_id_char || ']');

    -- Pega os owners que foram feito no expdp
    --EXPDP_ID_6_1 OWNER_EXPDP[X],TABLESPACE_TEMP[TEMP]
    --EXPDP_ID_6_2 OWNER_EXPDP[X],TABLESPACE_TEMP[TEMP]
    vContaReg     := 1;
    v_SelectOwner := 'SELECT t.object_name object_name  FROM ' ||
                     V_Job_name || ' t
                      where t.object_type_path = ''SCHEMA_EXPORT/USER''
                       and t.object_type = ''USER'' AND t.object_schema is not null';
    open c1 for v_SelectOwner;
    loop
      fetch c1
        into v_OwnerExpdp;
      exit when c1%notfound;
      select x.temporary_tablespace into vTempUserDefault from dba_users x
       where x.username = v_OwnerExpdp;
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_6_' || vContaReg || ' OWNER_EXPDP[' ||v_OwnerExpdp || '],TABLESPACE_TEMP['||vTempUserDefault||']');
      vContaReg := vContaReg + 1;
    end loop;
    close c1;

    -- EXPDP_ID_7 STATUS_EXPDP[X]
    execute immediate 'SELECT object_type_path  FROM ' || V_Job_name ||
                      ' t where operation = ''EXPORT'''
      INTO v_StatusExpdp;
    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_7 STATUS_EXPDP[' || v_StatusExpdp || ']');

    --EXPDP_ID_8_1 OWNER[X],OBJECT_NAME_INVALID[X]
    --EXPDP_ID_8_2 OWNER[X],OBJECT_NAME_INVALID[X]
    vContaReg := 1;
    For ni in (select owner, object_name
                 from dba_objects
                where status <> 'VALID' and owner = p_schema ) loop
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_8_' || vContaReg || ' OWNER[' || ni.owner ||
                        '],OBJECT_NAME_INVALID[' || ni.object_name || ']');
      vContaReg := vContaReg + 1;
    end loop;

    --EXPDP_ID_9_1 TIPO_OBJECT_ERRO[X],OWNER_ERRO_EXPDP[X],OBJECT_NAME_ERRO_EXPDP[X]
    --EXPDP_ID_9_2 TIPO_OBJECT_ERRO[X],OWNER_ERRO_EXPDP[X],OBJECT_NAME_ERRO_EXPDP[X]
    vContaReg     := 1;
    v_SelectOwner := 'SELECT object_type,object_schema,object_name FROM ' ||
                     V_Job_name || ' t
                      where processing_status = ''F''';
    open c3 for v_SelectOwner;
    loop
      fetch c3
        into vTpObjeto, vOwnerObjeto, vNmObjeto;
      exit when c3%notfound;
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_9_' || vContaReg || ' TIPO_OBJECT_ERRO[' ||
                        vTpObjeto || '],OWNER_ERRO_EXPDP[' || vOwnerObjeto ||
                        '],OBJECT_NAME_ERRO_EXPDP[' || vNmObjeto || ']');
      vContaReg := vContaReg + 1;
    end loop;
    close c3;

    -- EXPDP_ID_10 LOG_EXPDP[X]
    SELECT directory_path
         INTO v_CaminhoLogExpdp
      FROM all_directories
     WHERE upper(directory_name) = p_dump_dir;

    if substr(v_CaminhoLogExpdp,length(v_CaminhoLogExpdp),1) = '/' then
       p_Caminhoctl      := v_CaminhoLogExpdp || v_FileControle;
       v_CaminhoLogExpdp := v_CaminhoLogExpdp || v_logname;
    else
       p_Caminhoctl      := v_CaminhoLogExpdp || '/' || v_FileControle;
       v_CaminhoLogExpdp := v_CaminhoLogExpdp || '/' || v_logname;
    end if;

    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_10 LOG_EXPDP[' || v_CaminhoLogExpdp || ']');

    DBMS_DATAPUMP.detach(handle => dp_handle);
    execute immediate 'drop table ' || V_Job_name;
    utl_file.fclose_all;
  END TK_DISPARA_BACKUP_POR_OWNER;

  PROCEDURE TK_DISPARA_BACKUP_POR_FULL(p_dump_dir   IN VARCHAR2,
                                       p_dump_file  in varchar2 default null,
                                       p_log_file   in varchar2 default null,
                                       p_file_ctl   in varchar2 default null,
                                       p_degree     in number default null,
                                       p_FileSize   in varchar2 default '5G',
                                       p_Version    in varchar2 default 'COMPATIBLE',
                                       p_Caminhoctl out varchar2) IS
    dp_handle        NUMBER;
    job_status       VARCHAR2(30);
    v_dt             NUMBER;
    v_filename       VARCHAR2(100);
    v_logname        VARCHAR2(100);
    v_instance       v$instance.INSTANCE_NAME%type;
    v_Scn            v$database.CURRENT_SCN%type;
    v_DataInicio     varchar2(22) default to_char(sysdate,
                                                 'dd/mm/yyyy hh24:mi:ss');
    v_DataFim        varchar2(22);
    V_Job_name       varchar2(30);
    v_SelectFileN    varchar2(1000);
    v_SelectOwner    varchar2(1000);
    v_UserCorrente   varchar2(30);
    v_file_name      varchar2(1000);
    v_file_name_x    varchar2(1000);
    v_file_max_size  integer;
    v_OwnerExpdp     varchar2(30);
    TYPE cur_typ IS REF CURSOR;
    c                cur_typ;
    c1               cur_typ;
    c2               cur_typ;
    c3               cur_typ;
    RetornoDPFiles   TK_CLONEDB_DATAPUMP.TypeDumpFileV := TK_CLONEDB_DATAPUMP.TypeDumpFileV();
    v_version        v$instance.version%type;
    v_PonteiroCtl    utl_file.file_type;
    v_dbid           v$database.DBID%type;
    v_nameDb         v$database.NAME%type;
    v_Uk_nameDb      v$database.DB_UNIQUE_NAME%type;
    vContaReg        integer;
    vTpObjeto        varchar2(100);
    vOwnerObjeto     varchar2(100);
    vNmObjeto        varchar2(100);
    v_guid_id_char   varchar(100);
    v_FileControle   VARCHAR2(100);
    v_SelectTb       varchar2(32000);
    v_tb_name        varchar2(30);
    v_StatusExpdp    varchar2(1000);
    v_tb_tamBytes    number;
    vTempUserDefault dba_users.temporary_tablespace%type;
    v_OwnerBkpFull   dba_users.username%type;
    v_CaminhoLogExpdp varchar2(2000);
  BEGIN
    select sys_context('userenv', 'current_schema')
      into v_UserCorrente
      from dual;

    select upper(xx.INSTANCE_NAME) || '.', version
      into v_instance, v_version
      from v$instance xx;

    SELECT TO_NUMBER(TO_CHAR(SYSDATE, 'yyyymmddhh24mmss'))
      INTO v_dt
      FROM DUAL;

    select to_char(current_scn) into v_Scn from v$database;

    if p_dump_file is null then
      v_filename := v_instance || '' || 'FULL' || '%U' || '.' || v_dt ||'.dmp';
    else
      v_filename := p_dump_file;
    end if;

    if p_log_file is null then
      v_logname := v_instance || '' || 'FULL' || '.' || v_dt || '.log';
    else
      v_logname := p_log_file;
    end if;

    if p_file_ctl is null then
      v_FileControle := v_instance || '' || 'FULL' || '.' || v_dt || '.ctl';
    else
      v_FileControle := p_file_ctl;
    end if;

    V_Job_name := 'DP_' || TO_CHAR(sysdate, 'DD_MM_YYYY_HH24_MI_SS');

    dp_handle := DBMS_DATAPUMP.open(operation => 'EXPORT',
                                    job_mode  => 'FULL',
                                    version   => p_Version,
                                    job_name  => V_Job_name);

    dbms_datapump.set_parameter(dp_handle,
                                'CLIENT_COMMAND',
                                'Export (EXPDP) (arquivo de controle ÃƒÂ© ' ||
                                v_FileControle || ') full da instancia ' ||
                                upper(v_instance) || ' em ' ||
                                to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss'));
    dbms_datapump.set_parameter(dp_handle, 'FLASHBACK_SCN', v_Scn);
    dbms_datapump.set_parameter(dp_handle, 'METRICS', 1);
    -- Keep Master tem que ser 1
    dbms_datapump.set_parameter(dp_handle, 'KEEP_MASTER', 1);
    if p_degree is not null then
      dbms_datapump.set_parallel(handle => dp_handle, degree => p_degree);
    end if;
    -- dump file
    DBMS_DATAPUMP.add_file(handle    => dp_handle,
                           filename  => v_filename,
                           directory => p_dump_dir,
                           filesize  => upper(p_FileSize),
                           filetype  => SYS.DBMS_DATAPUMP.KU$_FILE_TYPE_DUMP_FILE);
    -- log file
    DBMS_DATAPUMP.add_file(handle    => dp_handle,
                           filename  => v_logname,
                           directory => p_dump_dir,
                           filetype  => SYS.DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);
    -- specify schema name

    DBMS_DATAPUMP.start_job(handle => dp_handle);
    DBMS_DATAPUMP.wait_for_job(handle    => dp_handle,
                               job_state => job_status);

    v_DataFim := to_char(sysdate, 'dd/mm/yyyy hh24:mi:ss');

    v_PonteiroCtl := utl_file.fopen(p_dump_dir, v_FileControle, 'W');

    vContaReg := 1;
    -- Pega todos os dump files gerados

    if instr(upper(v_filename),'%U') > 0 then
       v_SelectFileN := 'SELECT completed_bytes,file_name , reverse( substr( reverse(file_name),1, instr(reverse(file_name),''/'')-1)) File_name_x  FROM ' ||
                        V_Job_name || '
                              where USER_FILE_NAME is not null
                              and upper(file_name)  not like upper(''%' ||
                       v_filename || '%'') order by 1';
    else
       v_SelectFileN := 'SELECT completed_bytes,file_name , reverse( substr( reverse(file_name),1, instr(reverse(file_name),''/'')-1)) File_name_x  FROM ' ||
                        V_Job_name || '
                              where USER_FILE_NAME is not null
                              and upper(file_name)  like upper(''%' ||
                       v_filename || '%'') order by 1';
    end if;
    open c for v_SelectFileN;
    loop
      fetch c
        into v_file_max_size, v_file_name, v_file_name_x;
      exit when c%notfound;
      RetornoDPFiles := RetornoDumpfileInfo(p_dir  => p_dump_dir,
                                            p_file => v_file_name_x);

      -- EXPDP_ID_1_1 NM_FILE_DP[X],INTERNAL_DF_VERSION[X],FILE_NUMBER[X],LANG_NAME_CHAR[X],CREATE_DATE_DF[X],TAMANHO_BYTES[X]
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_1_' || vContaReg || ' NM_FILE_DP[' ||
                        v_file_name || '],INTERNAL_DF_VERSION[' ||
                        RetornoDPFiles(1) || '],FILE_NUMBER[' ||
                        RetornoDPFiles(4) || '],LANG_NAME_CHAR[' ||
                        RetornoDPFiles(11) || '],CREATE_DATE_DF[' ||
                        RetornoDPFiles(6) || '],TAMANHO_BYTES[' ||
                        v_file_max_size || ']');
      vContaReg := vContaReg + 1;
    end loop;
    v_guid_id_char := RetornoDPFiles(3);
    close c;

    select DBID, NAME, DB_UNIQUE_NAME
      into v_dbid, v_nameDb, v_Uk_nameDb
      from v$database;

    -- EXPDP_ID_2 DATA_INICIO_EXPDP[01/09/2017 HH24:MI:SS],DATA_FIM_EXPD[01/09/2017 HH24:MI:SS],DBID[XX],NAME:[DBPROD],DB_UNIQUE_NAME[DBPROD]
    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_2 DATA_INICIO_EXPDP[' || v_DataInicio ||
                      '],DATA_FIM_EXPDP[' || v_DataFim || '],DBID[' ||
                      v_dbid || '],NAME[' || v_nameDb ||
                      '],DB_UNIQUE_NAME[' || v_Uk_nameDb || ']');

    --EXPDP_ID_3_1 HOST_NAME[server1]
    --EXPDP_ID_3_2 HOST_NAME[server2]
    vContaReg := 1;
    For nx in (select t.host_name from gv$instance t) loop
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_3_' || vContaReg || ' HOST_NAME[' ||
                        nx.host_name || ']');
      vContaReg := vContaReg + 1;
    end loop;

    v_SelectTb := 'select owner,tablespace_name,sum(bytes) from dba_segments a,
               (SELECT t.object_name object_name  FROM ' || V_Job_name || ' t
                      where t.object_type_path = ''DATABASE_EXPORT/SCHEMA/USER''
                       and t.object_type = ''USER'' AND t.object_schema is not null) b
                        where a.owner = b.object_name
                          group by owner,tablespace_name order by 1';

    -- EXPDP_ID_4_1 OWNER[NOME],TABLESPACE_NAME[DATA],TAMANHO_BYTES[24234]
    -- EXPDP_ID_4_2 OWNER[NOME],TABLESPACE_NAME[DATA],TAMANHO_BYTES[24234]

    vContaReg := 1;
    open c2 for v_SelectTb;
    loop
      fetch c2
        into v_OwnerBkpFull,v_tb_name,v_tb_tamBytes;
      exit when c2%notfound;
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_4_' || vContaReg || ' OWNER['||v_OwnerBkpFull||'],TABLESPACE_NAME[' ||
                        v_tb_name || '],TAMANHO_BYTES[' ||
                        to_char(v_tb_tamBytes) || ']');
      vContaReg := vContaReg + 1;
    end loop;
    close c2;

    --EXPDP_ID_5 GUID_ID:[504B596A98BB73E4E0539B0AA8C02D63]
    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_5 GUID_ID[' || v_guid_id_char || ']');

    -- Pega os owners que foram feito no expdp
    --EXPDP_ID_6_1 OWNER_EXPDP[X],TABLESPACE_TEMP[TEMP]
    --EXPDP_ID_6_2 OWNER_EXPDP[X],TABLESPACE_TEMP[TEMP]
    vContaReg     := 1;
    v_SelectOwner := 'SELECT t.object_name object_name  FROM ' ||
                     V_Job_name || ' t
                      where t.object_type_path = ''DATABASE_EXPORT/SCHEMA/USER''
                       and t.object_type = ''USER'' AND t.object_schema is not null';
    open c1 for v_SelectOwner;
    loop
      fetch c1
        into v_OwnerExpdp;
       exit when c1%notfound;
       select x.temporary_tablespace into vTempUserDefault from dba_users x
       where x.username = v_OwnerExpdp;
       utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_6_' || vContaReg || ' OWNER_EXPDP[' ||v_OwnerExpdp || '],TABLESPACE_TEMP['||vTempUserDefault||']');
      vContaReg := vContaReg + 1;
    end loop;
    close c1;

    -- EXPDP_ID_7 STATUS_EXPDP[X]
    execute immediate 'SELECT object_type_path  FROM ' || V_Job_name ||
                      ' t where operation = ''EXPORT'''
      INTO v_StatusExpdp;
    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_7 STATUS_EXPDP[' || v_StatusExpdp || ']');

    --EXPDP_ID_8_1 OWNER[X],OBJECT_NAME_INVALID[X]
    --EXPDP_ID_8_2 OWNER[X],OBJECT_NAME_INVALID[X]
    vContaReg := 1;
    For ni in (select owner, object_name
                 from dba_objects
                where status <> 'VALID') loop
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_8_' || vContaReg || ' OWNER[' || ni.owner ||
                        '],OBJECT_NAME_INVALID[' || ni.object_name || ']');
      vContaReg := vContaReg + 1;
    end loop;

    --EXPDP_ID_9_1 TIPO_OBJECT_ERRO[X],OWNER_ERRO_EXPDP[X],OBJECT_NAME_ERRO_EXPDP[X]
    --EXPDP_ID_9_2 TIPO_OBJECT_ERRO[X],OWNER_ERRO_EXPDP[X],OBJECT_NAME_ERRO_EXPDP[X]
    vContaReg     := 1;
    v_SelectOwner := 'SELECT object_type,object_schema,object_name FROM ' ||
                     V_Job_name || ' t
                      where processing_status = ''F''';
    open c3 for v_SelectOwner;
    loop
      fetch c3
        into vTpObjeto, vOwnerObjeto, vNmObjeto;
      exit when c3%notfound;
      utl_file.put_line(v_PonteiroCtl,
                        'EXPDP_ID_9_' || vContaReg || ' TIPO_OBJECT_ERRO[' ||
                        vTpObjeto || '],OWNER_ERRO_EXPDP[' || vOwnerObjeto ||
                        '],OBJECT_NAME_ERRO_EXPDP[' || vNmObjeto || ']');
      vContaReg := vContaReg + 1;
    end loop;
    close c3;

    -- EXPDP_ID_10 LOG_EXPDP[X]
    SELECT directory_path
         INTO v_CaminhoLogExpdp
      FROM all_directories
     WHERE upper(directory_name) = p_dump_dir;

    if substr(v_CaminhoLogExpdp,length(v_CaminhoLogExpdp),1) = '/' then
       p_Caminhoctl      := v_CaminhoLogExpdp || v_FileControle;
       v_CaminhoLogExpdp := v_CaminhoLogExpdp || v_logname;
    else
       p_Caminhoctl      := v_CaminhoLogExpdp || '/' || v_FileControle;
       v_CaminhoLogExpdp := v_CaminhoLogExpdp || '/' || v_logname;
    end if;

    utl_file.put_line(v_PonteiroCtl,
                      'EXPDP_ID_10 LOG_EXPDP[' || v_CaminhoLogExpdp || ']');


    DBMS_DATAPUMP.detach(handle => dp_handle);
    execute immediate 'drop table ' || V_Job_name;
    utl_file.fclose_all;
  END TK_DISPARA_BACKUP_POR_FULL;

end TK_CLONEDB_DATAPUMP;
/