E:
call E:\Backup\rman\script\variaveis.bat 
cd %FOLDER_LOG%  

echo %date% - %time%" => Inicio do backup rman ..." > %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%
rman target / cmdfile=%FOLDER_SCRIPTS%\full.sql >> %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%
for /F %%i in ('findstr /I /M "RMAN-" %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%') do if /I "%%i" == "%FOLDER_LOG%\%FILE_LOG_RMAN_FULL%" goto ERRO
goto OK

:ERRO
echo %date% - %time%" => Fim do backup rman ...(E R R O!)" >> %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%
type %FOLDER_LOG%\%FILE_LOG_RMAN_FULL% >> %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%.erro
C:\Teiko\Farol\java\bin\java -jar C:\Teiko\Farol\lib\farolevent.jar --alvo=sesc --aplicacao=Backup_Teiko --severidade=2 --objeto=rmanfull_sesc --im=rmanfull_sesc  --mensagem="Backup fisico executado com erros."
goto LIMPA

:OK
echo %date% - %time%" => Fim do backup rman ...(S U C E S S O!)" >> %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%
type %FOLDER_LOG%\%FILE_LOG_RMAN_FULL% >> %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%.ok
C:\Teiko\Farol\java\bin\java -jar C:\Teiko\Farol\lib\farolevent.jar --alvo=sesc --aplicacao=Backup_Teiko --severidade=0 --objeto=rmanfull_sesc --im=rmanfull_sesc  --mensagem="Backup fisico executado com sucesso."
goto LIMPA

:LIMPA
del /q %FOLDER_LOG%\%FILE_LOG_RMAN_FULL%
echo > %FOLDER_LOG%\RMAN_FULL_temp.log
powershell -command (Get-Item "%FOLDER_LOG%\RMAN_FULL_temp.log").lastwritetime=$(Get-Date "12/07/2000")
forfiles /p %FOLDER_LOG% /m RMAN*.* /d -%RETENTION_LOG% /c "cmd /c del /q @FILE"
IF %ERRORLEVEL% NEQ 0 exit /b 0

:FIM
