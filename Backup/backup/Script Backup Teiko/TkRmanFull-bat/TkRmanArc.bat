E:
call E:\Backup\rman\script\variaveis.bat  
cd %FOLDER_LOG%  

echo %date% - %time%" => Inicio do backup rman ..." > %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%
rman target / cmdfile=%FOLDER_SCRIPTS%\archives.sql >>  %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%
for /F %%i in ('findstr /I /M "RMAN-" %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%') do if /I "%%i" == "%FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%" goto ERRO
goto OK

:ERRO
echo %date% - %time%" => Fim do backup rman ...(E R R O!)" >> %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%
type %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH% >> %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%.erro
C:\Teiko\Farol\java\bin\java -jar C:\Teiko\Farol\lib\farolevent.jar --alvo=sesc --aplicacao=Backup_Teiko --severidade=2 --objeto=rmanarch_sesc  --im=rmanarch_sesc  --mensagem="Backup archive executado com erro."
goto LIMPA

:OK
echo %date% - %time%" => Fim do backup rman ...(S U C E S S O!)" >> %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%
type %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH% >> %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%.ok
C:\Teiko\Farol\java\bin\java -jar C:\Teiko\Farol\lib\farolevent.jar --alvo=sesc --aplicacao=Backup_Teiko --severidade=0 --objeto=rmanarch_sesc --im=rmanarch_sesc  --mensagem="Backup archive executado com sucesso."
goto LIMPA

:LIMPA
del /q %FOLDER_LOG%\%FILE_LOG_RMAN_ARCH%
echo > %FOLDER_LOG%\RMAN_ARCH_temp.log
powershell -command (Get-Item "%FOLDER_LOG%\RMAN_ARCH_temp.log").lastwritetime=$(Get-Date "12/07/2000")
forfiles /p %FOLDER_LOG% /m RMAN*.* /d -%RETENTION_LOG% /c "cmd /c del /q @FILE"
IF %ERRORLEVEL% NEQ 0 exit /b 0

:FIM






