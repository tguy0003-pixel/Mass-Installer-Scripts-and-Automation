@ECHO OFF
TITLE Enterprise Lab Installer Launcher

:: Check for Admin rights using FSUTIL
FSUTIL DIRTY QUERY %systemdrive% >nul
IF %ERRORLEVEL% EQU 0 (
    ECHO Admin rights confirmed. Starting deployment sequence...
    
    :: Use PUSHD to ensure the script path is handled correctly on USB drives
    PUSHD "%~dp0"
    
    :: Bypass ExecutionPolicy and launch the PowerShell worker script
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "enterprise_install.ps1"
    
    POPD
    ECHO.
    ECHO Deployment sequence finished.
    PAUSE
) ELSE (
    ECHO Requesting Administrator privileges...
    :: Relaunch this file (%~f0) with "RunAs" (Admin) privileges via PowerShell
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
)
EXIT
