rem @echo off
setlocal

start cmd.exe

rem
rem It seems redirections like 2>nul don't work correctly, so avoid them in this script
rem

if "%SystemDrive%"=="" (
    echo System drive was not specified.
    goto :eof
)

if "%SystemRoot%"=="" (
    echo Windows directory was not specified.
    goto :eof
)

set ProgramFiles(x86)=%SystemDrive%\Program Files (x86)

%SystemRoot%\system32\secinit.exe

:DoInstall
%SystemRoot%\system32\oobe\setup.exe

if errorlevel 1 (
echo Error in running setup.exe
echo More error information may be available in 
echo %systemroot%\panther\setupact.log and
echo %systemroot%\panther\setuperr.log
pause
goto :DoInstall
)

rem
rem Delete SetupPolicies directory
rem

if exist %SystemRoot%\WinSxS\SetupPolicies\nul (
    rd /s /q %SystemRoot%\WinSxS\SetupPolicies
)
popd
