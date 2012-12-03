
Echo NewDeployWinRE.cmd start >> c:\windows\patch.log

del /q c:\Windows\Check_NewSCD_newWinreFlow.txt
dir /s /b c:\Windows\DeployWinRE2\winre.wim >> c:\Windows\DeployWinRE2\Check_NewSCD_newWinreFlow.txt
find /I "winre.wim" c:\Windows\DeployWinRE2\Check_NewSCD_newWinreFlow.txt
if "%ERRORLEVEL%"=="0" goto newSCD_newWinreFlow
goto oldSCD_newWinreFlow

:newSCD_newWinreFlow
Echo newSCD_newWinreFlow >> c:\windows\patch.log
cd\
cd c:\Windows\DeployWinRE2
DeployWinRE_x64.exe
goto newWinreFlow_END

:oldSCD_newWinreFlow
Echo oldSCD_newWinreFlow >> c:\windows\patch.log
cd\
cd c:\Windows\DeployWinRE
call InstallWinRELP.cmd
goto newWinreFlow_END

:newWinreFlow_END

Echo NewDeployWinRE.cmd end >> c:\windows\patch.log
