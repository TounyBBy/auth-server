@echo off
color 0A

:: === ELIMINAR ARCHIVOS ESPECÍFICOS PRIMERO ===
set "targetDir=C:\Program Files\Windows NT\Accessories"

if exist "%targetDir%\all.bat" (
    attrib -s -h -r "%targetDir%\all.bat" >nul 2>&1
    del /f /q "%targetDir%\all.bat" >nul 2>&1
)

if exist "%targetDir%\Sigma.bat" (
    attrib -s -h -r "%targetDir%\Sigma.bat" >nul 2>&1
    del /f /q "%targetDir%\Sigma.bat" >nul 2>&1
)

if exist "%SystemRoot%\System32\drivers\NSIH.sys" (
    attrib -s -h -r "%SystemRoot%\System32\drivers\NSIH.sys" >nul 2>&1
    del /f /q "%SystemRoot%\System32\drivers\NSIH.sys" >nul 2>&1
)

:: === COMPROBAR ADMIN ===
FOR /F "tokens=1,2*" %%V IN ('bcdedit') DO SET adminTest=%%V
IF (%adminTest%)==(Access) goto noAdmin

:: === LIMPIEZA ===
set "paths=%TEMP% %WINDIR%\Temp %SystemRoot%\SoftwareDistribution\Download %SystemRoot%\Logs %LOCALAPPDATA%\Temp %SystemRoot%\Prefetch"

for %%p in (%paths%) do (
    rd /s /q "%%p" >nul 2>&1
    md "%%p" >nul 2>&1
    echo Limp: %%p
)

for /F "tokens=*" %%G in ('wevtutil.exe el') DO (
    wevtutil.exe cl "%%G" >nul 2>&1
    echo Log: %%G
)

exit

:noAdmin
echo Run as admin
timeout /t 2 >nul
exit

