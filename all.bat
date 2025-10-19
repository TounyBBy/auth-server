@echo off
setlocal enabledelayedexpansion

rem --- logfile ---
set "LOG=%temp%\ac_install.log"
echo -------------------------------------------------- >> "%LOG%"
echo %date% %time% - Ejecutando %~f0 >> "%LOG%"

rem --- comprobar si ya somos admin (usamos whoami /groups para una comprobación robusta) ---
whoami /groups | findstr /I "S-1-5-32-544" >nul 2>&1
if errorlevel 1 (
    rem crear VBScript para relanzar con elevación
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    echo %date% %time% - No había privilegios, solicitando elevacion... >> "%LOG%"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs" >nul 2>&1
    exit /B
)

echo %date% %time% - Ejecutando con privilegios elevados. >> "%LOG%"

rem --- comprobar que el archivo ac.sys existe en la misma carpeta que el .bat ---
if not exist "%~dp0ac.sys" (
    echo ERROR: ac.sys no encontrado en %~dp0 >> "%LOG%"
    echo ERROR: ac.sys no encontrado en %~dp0
    pause
    exit /B 1
)
echo %date% %time% - ac.sys encontrado. >> "%LOG%"

rem --- comprobar si el servicio 'ac' ya existe ---
sc query ac >nul 2>&1
if %errorlevel%==0 (
    echo %date% %time% - Servicio 'ac' ya existe. No se creara de nuevo. >> "%LOG%"
    echo Servicio 'ac' ya existe.
) else (
    rem crear servicio kernel apuntando al driver
    echo %date% %time% - Creando servicio 'ac'... >> "%LOG%"
    sc create ac type= kernel start= auto binPath= "%~dp0ac.sys" >> "%LOG%" 2>&1
    if errorlevel 1 (
        echo ERROR: Fallo al crear el servicio 'ac'. >> "%LOG%"
        echo ERROR: Fallo al crear el servicio 'ac'. Revisa %LOG%.
        pause
        exit /B 1
    ) else (
        echo Servicio 'ac' creado correctamente. >> "%LOG%"
        echo Servicio 'ac' creado correctamente.
    )
)

rem --- intentar iniciar el servicio si no esta en ejecución ---
sc query ac | findstr /i /c:"RUNNING" >nul 2>&1
if %errorlevel%==0 (
    echo %date% %time% - Servicio 'ac' ya en ejecucion. >> "%LOG%"
    echo Servicio 'ac' ya en ejecucion.
) else (
    echo %date% %time% - Intentando iniciar servicio 'ac'... >> "%LOG%"
    sc start ac >> "%LOG%" 2>&1
    if errorlevel 1 (
        echo WARNING: No se pudo iniciar el servicio 'ac'. Revisa Event Viewer y %LOG% para mas detalles. >> "%LOG%"
        echo WARNING: No se pudo iniciar el servicio 'ac'. Revisa Event Viewer y %LOG%.
    ) else (
        echo Servicio 'ac' iniciado correctamente. >> "%LOG%"
        echo Servicio 'ac' iniciado correctamente.
    )
)

rem --- espera corta para que el estado se estabilice y mostrar estado final ---
timeout /t 2 /nobreak >nul
sc query ac >> "%LOG%" 2>&1

exit

