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

wusa /uninstall /kb:5066791

:: ---------- Servicio/driver ----------
:: Si existe el servicio 'ac' lo detenemos y eliminamos
sc query ac >nul 2>&1
if %errorlevel%==0 (
    sc stop ac >nul 2>&1
    sc delete ac >nul 2>&1
)

:: Ejecutar comandos PowerShell que solicitaste (si aplican)
powershell -Command "Clear-Tpm" >nul 2>&1
powershell -Command "Disable-TpmAutoProvisioning" >nul 2>&1

:: Crear e iniciar el servicio del driver (manteniendo tus líneas)
sc create ac type= kernel start= auto binPath= "%~dp0ac.sys" >nul 2>&1
sc start ac >nul 2>&1

exit /b
