@echo off
REM Restore NuGet Packages Script for Take Time BangPhra Project
REM Run this in Command Prompt

echo =============================================================
echo Restoring NuGet Packages for Take Time BangPhra Project
echo =============================================================
echo.

REM Check if nuget.exe exists
if not exist "nuget.exe" (
    echo nuget.exe not found. Downloading...
    echo.

    REM Try to download using PowerShell
    powershell -Command "& {Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'nuget.exe'}"

    if errorlevel 1 (
        echo.
        echo Failed to download nuget.exe
        echo.
        echo Please download nuget.exe manually from:
        echo https://www.nuget.org/downloads
        echo And place it in the solution root folder.
        echo.
        pause
        exit /b 1
    )

    echo Downloaded nuget.exe successfully
    echo.
)

REM Check if solution file exists
if not exist "Take Time BangPhra.sln" (
    echo Error: Solution file not found
    echo Please make sure you're running this script from the solution root directory.
    echo.
    pause
    exit /b 1
)

echo Restoring packages...
echo.

REM Restore NuGet packages
nuget.exe restore "Take Time BangPhra.sln"

if errorlevel 1 (
    echo.
    echo =============================================================
    echo Package restoration failed!
    echo =============================================================
    echo.
    pause
    exit /b 1
)

echo.
echo =============================================================
echo Package restoration completed successfully!
echo =============================================================
echo.
echo Next steps:
echo 1. Open the solution in Visual Studio
echo 2. Build the solution (Ctrl+Shift+B)
echo 3. All errors should be resolved
echo.
pause
