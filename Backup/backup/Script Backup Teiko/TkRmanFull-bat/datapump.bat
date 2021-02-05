@ECHO ON

g:
call G:\TEIKO\datapump_rm121181\scripts\owerRMandTOTVSAUDIT\variaveis_logico.bat 
cd %FOLDER_LOG%

IF %time:~0,2% LEQ 9 ( 
  set INICIO_BACKUP=%date% - 0%time:~1,1%:%time:~3,2%:%time:~6,2%
) ELSE (
  set INICIO_BACKUP=%date% - %time:~0,2%:%time:~3,2%:%time:~6,2%
)

set ERRO_BKP=-1

set DIR_LOG_BACKUP=%FOLDER_LOG%\

set DIR_DUMP=%LOCAL_DMP%\

set DIR_DUMP_LOG=%LOCAL_DMP_LOG%\



IF %time:~0,2% LEQ 9 ( 
  set DUMP_FILE=EXP_%ORACLE_SID%_%date:~6,4%%date:~3,2%%date:~0,2%0%time:~1,1%%time:~3,2%%time:~6,2%
) ELSE (
  set DUMP_FILE=EXP_%ORACLE_SID%_%date:~6,4%%date:~3,2%%date:~0,2%%time:~0,2%%time:~3,2%%time:~6,2%
)

set COMPACTA_BACKUP=0

ECHO "--> INICIO DO BACKUP" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO.

ECHO "--> INICIO DO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log  
ECHO.

I:\app\oracle\product\11.2.0.4\dbhome_1\bin\expdp.exe teikobkp/bkpokiet@rm121181 full=y directory=teiko_dpump_new dumpfile=%DUMP_FILE%.dmp logfile=%DUMP_FILE%.log consistent=y


move %DIR_DUMP%%DUMP_FILE%.log %DIR_DUMP_LOG%

find "successfully completed" %DIR_DUMP_LOG%%DUMP_FILE%.log

IF %ERRORLEVEL% NEQ 0 (
  ECHO "--> ERRO NO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log  
  ECHO.
  set ERRO_BKP=1
  "C:\Program Files (x86)\WinRAR\rar" a -s  %DIR_DUMP%%DUMP_FILE%.rar %DIR_DUMP%%DUMP_FILE%.*
  goto :RESUMO
) 
  
ECHO "--> FIM DO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO.

IF %COMPACTA_BACKUP% EQU 1 ( 
  
    ECHO "--> INICIO DA COMPACTACAO DOS ARQUIVOS DO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  ECHO.

  "C:\Program Files\WinRAR\rar" a -s  %DIR_DUMP%%DUMP_FILE%.rar %DIR_DUMP%%DUMP_FILE%.*

  IF EXIST %DIR_DUMP%%DUMP_FILE%.rar (
    ECHO "--> FIM DA COMPACTACAO DOS ARQUIVOS DO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
    ECHO.
    ECHO "--> REMOVENDO ARQUIVOS DO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
    ECHO.
    del /q  %DIR_DUMP%%DUMP_FILE%.dmp
    ECHO "--> ARQUIVOS DO EXPORT FULL REMOVIDOS" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
    ECHO.
    ECHO "--> FIM DO BACKUP/BACKUP FINALIZADO COM SUCESSO" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
    set ERRO_BKP=0
    goto :RESUMO
  ) ELSE (
    ECHO "--> ERRO NA COMPACTACAO DOS ARQUIVOS DO EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
    set ERRO_BKP=1
    goto :RESUMO
  )
) ELSE (
  ECHO "--> FIM DO BACKUP/BACKUP FINALIZADO COM SUCESSO" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  set ERRO_BKP=0
  goto :RESUMO
)

:RESUMO
ECHO. >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO. >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log
ECHO "********************RESUMO********************" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO. >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO "HOSTNAME                    : %COMPUTERNAME%" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO "ORACLE_SID                  : %ORACLE_SID%" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO "TIPO DE BACKUP              : LOGICO/EXPORT FULL" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
IF EXIST %DIR_DUMP%%DUMP_FILE%.rar (
  ECHO "ARQUIVO DE DUMP             : %DIR_DUMP%%DUMP_FILE%.dmp" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  ECHO "ARQUIVO DE LOG              : %DIR_DUMP_LOG%%DUMP_FILE%.log" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  ECHO "ARQUIVO COMPACTADO DO BACKUP: %DIR_DUMP%%DUMP_FILE%.rar" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
) ELSE (
  IF EXIST %DIR_DUMP%%DUMP_FILE%.dmp ( 
    ECHO "ARQUIVO DE DUMP             : %DIR_DUMP%%DUMP_FILE%.dmp" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  )
  IF EXIST %DIR_DUMP_LOG%%DUMP_FILE%.log (
    ECHO "ARQUIVO DE LOG              : %DIR_DUMP_LOG%%DUMP_FILE%.log" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  )
)

IF %time:~0,2% LEQ 9 ( 
  set FIM_BACKUP=%date% - 0%time:~1,1%:%time:~3,2%:%time:~6,2%
) ELSE (
  set FIM_BACKUP=%date% - %time:~0,2%:%time:~3,2%:%time:~6,2%
)

ECHO "INICIO DO BACKUP            : %INICIO_BACKUP%" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
ECHO "FIM DO BACKUP               : %FIM_BACKUP%" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 

IF %ERRO_BKP% EQU 0 (
  ECHO "SITUACAO DO BACKUP          : FINALIZADO COM SUCESSO" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  move %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.ok
  C:\Teiko\Farol\java\bin\java -jar C:\Teiko\Farol\lib\farolevent.jar --alvo=rm121181 --aplicacao=Backup_Teiko --severidade=0 --objeto=expdp_rm121181 --im=expdp_rm121181  --mensagem="Backup logico executado com sucesso."
) ELSE (
  ECHO "SITUACAO DO BACKUP          : FINALIZADO COM ERRO" >> %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log 
  move %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.log %DIR_LOG_BACKUP%EXP_RM_TOTVSAUDIT_%DUMP_FILE%.erro
  C:\Teiko\Farol\java\bin\java -jar C:\Teiko\Farol\lib\farolevent.jar --alvo=rm121181 --aplicacao=Backup_Teiko --severidade=2 --objeto=expdp_rm121181 --im=expdp_rm121181  --mensagem="Backup logico executado com erro."
)

forfiles /p %FOLDER_LOG% /m EXP*.* /d -%RETENTION_LOG% /c "cmd /c del /q @FILE" 

forfiles /p %DIR_DUMP% /m EXP*.* /d -%RETENTION_DMP% /c "cmd /c del /q @FILE" 

forfiles /p %DIR_DUMP_LOG% /m EXP*.* /d -%RETENTION_DMP% /c "cmd /c del /q @FILE" 


