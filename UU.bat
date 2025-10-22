@echo off
chcp 850 >nul
title FORCE ROLLUPFIX REMOVER (Ultimate)
color 0C

echo ==========================================
echo     FORCE ROLLUPFIX REMOVAL TOOL
echo ==========================================
echo.

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

:end
echo.
echo ==========================================
echo [✓] Proceso finalizado. Reinicia el PC.
echo ==========================================
pause
exit /b
