@echo off
REM --- Detiene y elimina un servicio llamado "ac" si existe ---
sc query ac >nul 2>&1
if %errorlevel%==0 (
    echo Deteniendo servicio existente 'ac'...
    sc stop ac >nul 2>&1
    echo Eliminando servicio 'ac'...
    sc delete ac >nul 2>&1
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

exit

