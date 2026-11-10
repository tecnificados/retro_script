@echo off
setlocal
set "SCRIPT=%~dp0setup-retro-portable.ps1"

if not exist "%SCRIPT%" (
    echo No se encuentra: "%SCRIPT%"
    pause
    exit /b 2
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RESULT=%ERRORLEVEL%"

if not "%RESULT%"=="0" (
    echo.
    echo La configuracion termino con errores. Consulta setup.log.
) else (
    echo.
    echo Configuracion completada. Consulta setup.log para ver el registro.
)
pause
exit /b %RESULT%
