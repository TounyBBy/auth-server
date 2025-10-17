@echo off
color 0A

FOR /F "tokens=1,2*" %%V IN ('bcdedit') DO SET adminTest=%%V
IF (%adminTest%)==(Access) goto noAdmin

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
