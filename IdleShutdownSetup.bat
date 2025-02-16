@echo off
:: Ensure the script is running as Administrator (UAC Elevation)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Define necessary variables
set "SCRIPT_DIR=%~dp0"
set "TASK_NAME=IdleShutdown"
set "IDLESHUTDOWN_EXE=%SCRIPT_DIR%IdleShutdown.exe"
set "HIBERNATE_SCRIPT=%SCRIPT_DIR%hibernate.bat"

:: Ask the user if they want to enable or disable auto power-off
echo =====================================================
echo          Auto Power-Off Configuration
echo =====================================================
echo This script allows you to automatically turn off or hibernate
echo your computer after a set period of inactivity.
echo.
echo Select an option:
echo [1] Enable auto power-off (Shutdown or Hibernate after inactivity)
echo [2] Disable auto power-off (Remove existing scheduled task)
set /p ENABLE_POWER_OFF="Enter your choice (1 or 2): "

if "%ENABLE_POWER_OFF%"=="2" (
    echo.
    echo Disabling auto power-off...
    schtasks /delete /tn "%TASK_NAME%" /f
    echo Auto power-off has been disabled. Your computer will no longer shut down automatically.
    pause
    exit /b
) else if not "%ENABLE_POWER_OFF%"=="1" (
    echo.
    echo Invalid choice. Please enter 1 or 2.
    pause
    exit /b
)

:: Ensure IdleShutdown.exe exists, download if missing
:exeCheck
if not exist "%IDLESHUTDOWN_EXE%" (
    echo.
    echo IdleShutdown.exe was not found in %SCRIPT_DIR%.
    echo Downloading the latest version from GitHub...
    
    curl -L -o "%IDLESHUTDOWN_EXE%" https://github.com/fuzzdeveloper/IdleShutdown/releases/latest/download/IdleShutdown.exe

    timeout /t 3 /nobreak >nul

    if not exist "%IDLESHUTDOWN_EXE%" (
        echo.
        echo Download failed. Retrying...
        goto exeCheck
    )

    echo.
    echo IdleShutdown.exe successfully downloaded.
)

:: Ask the user for idle time before power-off
echo.
echo =====================================================
echo      Set Idle Time Before Power-Off
echo =====================================================
echo Enter the number of minutes your computer must be **completely idle**
echo before the selected power-off action (Shutdown or Hibernate) occurs.
echo Example: Enter "60" for 1 hour of inactivity.
set /p IDLE_TIME="Enter idle time in minutes: "
set /a IDLE_SECONDS=%IDLE_TIME% * 60

:: Ask the user whether to Hibernate or Shutdown
echo.
echo =====================================================
echo      Choose Power-Off Action After Inactivity
echo =====================================================
echo Select what happens when the idle time is reached:
echo [1] Hibernate - Saves your session and powers down (recommended for laptops)
echo [2] Shutdown - Closes all programs and turns off the computer
set /p ACTION_CHOICE="Enter your choice (1 or 2): "

if "%ACTION_CHOICE%"=="1" (
    set "ACTION_COMMAND=shutdown.exe /h"
    echo Hibernate selected. Your computer will hibernate after %IDLE_TIME% minutes of inactivity.
) else if "%ACTION_CHOICE%"=="2" (
    set "ACTION_COMMAND=shutdown.exe /s /t 0"
    echo Shutdown selected. Your computer will completely shut down after %IDLE_TIME% minutes of inactivity.
) else (
    echo.
    echo Invalid choice. Please enter 1 or 2.
    pause
    exit /b
)

:: Create hibernate.bat if it does not exist
if not exist "%HIBERNATE_SCRIPT%" (
    echo @echo off > "%HIBERNATE_SCRIPT%"
    echo %ACTION_COMMAND% >> "%HIBERNATE_SCRIPT%"
)

:: Register the IdleShutdown task for all users
schtasks /create /tn "%TASK_NAME%" /tr "\"%IDLESHUTDOWN_EXE%\" %IDLE_SECONDS% 60 \"%HIBERNATE_SCRIPT%\"" /sc onlogon /ru "SYSTEM" /rl highest /f

echo.
echo =====================================================
echo       Auto Power-Off Task Successfully Created
echo =====================================================
echo Your computer will now %ACTION_COMMAND% after %IDLE_TIME% minutes of inactivity.
echo The task has been registered and will run automatically at startup.
pause
