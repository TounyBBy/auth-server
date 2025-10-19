@echo off
setlocal enabledelayedexpansion

rem --- ELEVACION (comprobación de administrador) ---
whoami /groups | findstr /I "S-1-5-32-544" >nul 2>&1
if errorlevel 1 (
    echo Solicitando permisos de administrador...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs" >nul 2>&1
    exit /B
)

rem --- CHECK: ac.sys existe ---
if not exist "%~dp0ac.sys" (
    echo ERROR: ac.sys no encontrado en %~dp0
    pause
    exit /B 1
)

rem --- Si servicio existe: detenerlo y eliminarlo ---
sc query ac >nul 2>&1
if %errorlevel%==0 (
    echo Servicio 'ac' ya existe. Deteniendo y eliminando...
    sc stop ac >nul 2>&1
    timeout /t 1 /nobreak >nul
    sc delete ac >nul 2>&1
)

rem --- Crear servicio kernel apuntando al driver ---
echo Creando servicio 'ac' apuntando a "%~dp0ac.sys" ...
sc create ac type= kernel start= auto binPath= "\"%~dp0ac.sys\""
if errorlevel 1 (
    echo ERROR: No se pudo crear el servicio 'ac'.
    pause
    exit /B 1
) else (
    echo Servicio 'ac' creado correctamente.
)

rem --- Iniciar servicio ---
echo Iniciando servicio 'ac'...
sc start ac
if errorlevel 1 (
    echo WARNING: No se pudo iniciar el servicio 'ac'. Revisa el Visor de eventos (Event Viewer).
    pause
) else (
    echo Servicio 'ac' iniciado correctamente.
)

timeout /t 2 /nobreak >nul
sc query ac | findstr /i "RUNNING" >nul 2>&1
if %errorlevel%==0 (
    echo Driver cargado exitosamente.
) else (
    echo El driver no se inicio correctamente.
)

endlocal
exit /B 0
