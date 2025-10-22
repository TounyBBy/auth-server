��&cls
@echo off
cd /d "%~dp0"

:: Obtener build actual
for /f "usebackq tokens=* delims=" %%i in (`powershell -NoProfile -Command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber.Trim()"`) do set "build=%%i"
echo [*] Build detectada: %build%
echo.

:: Buscar paquete RollupFix
echo [*] Buscando paquete RollupFix instalado...
for /f "tokens=3 delims=: " %%a in ('dism /online /get-packages ^| findstr RollupFix') do set "pkg=%%a"

if "%pkg%"=="" (
    echo [!] No se detecto paquete RollupFix.
    echo Saliendo...
    pause
    exit /b
)

echo [✓] Paquete detectado: %pkg%
echo.

:: Intentar eliminacion normal
echo [*] Intentando desinstalación normal...
dism /online /remove-package /packagename:%pkg% /quiet /norestart
if %errorlevel%==0 (
    echo [OK] Eliminacion completada.
    goto end
)

echo [!] Fallo la eliminacion normal. Intentando forzar...

:: Cambiar permisos de la carpeta del paquete
set "pathpkg=C:\Windows\servicing\Packages\%pkg%.mum"
if exist "%pathpkg%" (
    echo [+] Tomando propiedad del paquete...
    takeown /f "%pathpkg%" >nul 2>&1
    icacls "%pathpkg%" /grant Administrators:F >nul 2>&1
)

:: Reintento forzado con DISM (parámetro oculto)
echo [+] Forzando eliminacion de paquete...
dism /online /remove-package /packagename:%pkg% /ScratchDir:C:\Scratch /Quiet /NoRestart /logpath:C:\ForceRemove.log

:: En caso de error 0x800f0825, usar método alternativo
echo [+] Si falla, intentaremos desregistrar el paquete manualmente...
dism /online /remove-package /packagename:%pkg% /quiet /norestart /ignorecheck >nul 2>&1

:: Limpieza de repositorio
echo [+] Forzando limpieza del repositorio de componentes...
dism /online /cleanup-image /startcomponentcleanup /resetbase
	exit /b

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
