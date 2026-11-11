@echo off
setlocal
set "ROOT=%~dp0"

if not exist "%ROOT%setup-retro-portable.ps1" (
    echo ERROR: setup-retro-portable.ps1 was not found next to this file.
    pause
    exit /b 2
)

echo This will remove the downloaded cache and generated portable installation:
echo   .setup-cache, Emulators, ES-DE, Games, ES-DE.incomplete
echo   run-retro-portable.bat and setup.log
echo Source scripts, documentation, LICENSE, extra_games.csv and metadata_sources.csv will be kept.
choice /C SN /N /M "Continue? [S/N]: "
if errorlevel 2 goto cancelled

if exist "%ROOT%.setup-cache" rmdir /s /q "%ROOT%.setup-cache"
if exist "%ROOT%Emulators" rmdir /s /q "%ROOT%Emulators"
if exist "%ROOT%ES-DE" rmdir /s /q "%ROOT%ES-DE"
if exist "%ROOT%ES-DE.incomplete" rmdir /s /q "%ROOT%ES-DE.incomplete"
if exist "%ROOT%Games" rmdir /s /q "%ROOT%Games"
if exist "%ROOT%run-retro-portable.bat" del /q "%ROOT%run-retro-portable.bat"
if exist "%ROOT%setup.log" del /q "%ROOT%setup.log"

echo Cleanup completed. Source files, extra_games.csv and metadata_sources.csv were kept.
pause
exit /b 0

:cancelled
echo Cleanup cancelled. No files were removed.
pause
exit /b 1
