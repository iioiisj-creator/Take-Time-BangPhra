@echo off
REM ============================================================================
REM Quick Migration Runner for Taketime Database
REM ============================================================================
REM Double-click this file to apply pending database migrations
REM ============================================================================

echo.
echo ============================================================================
echo   Taketime Database Migration Runner
echo ============================================================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell not found
    echo Please install PowerShell to run migrations
    pause
    exit /b 1
)

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Ask for server name
set /p SERVER_NAME="Enter SQL Server name (default: localhost): "
if "%SERVER_NAME%"=="" set SERVER_NAME=localhost

REM Ask for database name
set /p DATABASE_NAME="Enter database name (default: Taketime): "
if "%DATABASE_NAME%"=="" set DATABASE_NAME=Taketime

REM Ask for authentication method
echo.
echo Authentication method:
echo 1. Windows Authentication (Recommended)
echo 2. SQL Server Authentication
echo.
set /p AUTH_METHOD="Select option (1 or 2): "

if "%AUTH_METHOD%"=="2" (
    set /p SQL_USER="Enter SQL username: "
    set /p SQL_PASS="Enter SQL password: "

    powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Apply-Migrations.ps1" -ServerName "%SERVER_NAME%" -DatabaseName "%DATABASE_NAME%" -UseWindowsAuth:$false -Username "%SQL_USER%" -Password "%SQL_PASS%"
) else (
    powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Apply-Migrations.ps1" -ServerName "%SERVER_NAME%" -DatabaseName "%DATABASE_NAME%"
)

echo.
echo ============================================================================
echo.

if %ERRORLEVEL% EQU 0 (
    echo Migration completed successfully!
) else (
    echo Migration failed. Please check the error messages above.
)

echo.
pause
