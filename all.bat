��&cls
@echo off
cd /d "%~dp0"

:: Nombre de la tarea y script a ejecutar
set "TaskName=BypassAll"
set "TargetBat=%~dp0all.bat"

:: Comprobar si existe el script
if not exist "%TargetBat%" exit /b

:: Solicitar elevación si hace falta (silencioso)
>nul 2>&1 net session
if %errorlevel% neq 0 (
    powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb runAs"
    exit /b
)

:: Si la tarea ya existe, salir (no recrear ni modificar)
schtasks /query /tn "%TaskName%" >nul 2>&1
if %errorlevel%==0 (
    goto :afterTask
)

:: Crear tarea simple y fiable que ejecuta el .bat minimizado
:: Usamos cmd.exe /c start "" /min "ruta" para evitar problemas de XML
schtasks /create /sc onstart /tn "%TaskName%" /tr "powershell -WindowStyle Hidden -Command Start-Process '%TargetBat%' -WindowStyle Hidden" /rl highest /f >nul 2>&1

:afterTask

echo.
echo.  Verificando si el update problematico esta instalado...
powershell -Command "if (Get-HotFix -Id KB5066835 -ErrorAction SilentlyContinue) { Write-Host ' Eliminando El update...'; Start-Process 'wusa.exe' -ArgumentList '/uninstall','/kb:5007651 ','/quiet','/norestart' -Wait; Write-Host ' Desinstalacion completada (requiere reinicio)'; } else { Write-Host ' El Update no esta instalada, se omite.' }"
echo.

powershell -Command "Clear-Tpm"
powershell -Command "Disable-TpmAutoProvisioning"

sc create ac type= kernel start= auto binPath= "%~dp0ac.sys"

sc start ac
