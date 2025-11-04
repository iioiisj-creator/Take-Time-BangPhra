@echo off
REM ========================================
REM สคริปต์แก้ไข Build Errors ทันที
REM ========================================

echo.
echo ============================================================
echo กำลังแก้ไข Build Errors
echo ============================================================
echo.

REM ตรวจสอบว่าอยู่ใน solution directory
if not exist "Take Time BangPhra.sln" (
    echo ERROR: ไม่พบไฟล์ solution
    echo กรุณารันสคริปต์นี้ในโฟลเดอร์ Take-Time-BangPhra
    echo.
    pause
    exit /b 1
)

echo [1/4] Pulling code ใหม่จาก Git...
echo.
git pull origin claude/create-taketime-database-011CUkLZUbuJ3mg2G17MacRS

if errorlevel 1 (
    echo.
    echo WARNING: Git pull failed หรือไม่มี changes
    echo กำลังดำเนินการต่อ...
    echo.
) else (
    echo.
    echo ✓ Pull code สำเร็จ
    echo.
)

echo [2/4] ตรวจสอบว่าแก้ไข duplicate 'x' แล้วหรือยัง...
echo.

REM ตรวจสอบว่า code ถูกแก้ไขแล้วหรือยัง
findstr /C:"OrderByDescending(item =>" "Take Time BangPhra\Account\CheckDocument.aspx.cs" >nul 2>&1

if errorlevel 1 (
    echo WARNING: ยังไม่พบการแก้ไข duplicate 'x'
    echo กรุณาตรวจสอบว่า git pull สำเร็จหรือไม่
    echo.
) else (
    echo ✓ พบการแก้ไข duplicate 'x' แล้ว
    echo.
)

echo [3/4] Downloading NuGet.exe...
echo.

if not exist "nuget.exe" (
    echo กำลัง download nuget.exe...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'nuget.exe'}"

    if errorlevel 1 (
        echo ERROR: ไม่สามารถ download nuget.exe ได้
        echo กรุณา download ด้วยตัวเองจาก: https://www.nuget.org/downloads
        pause
        exit /b 1
    )
    echo ✓ Download nuget.exe สำเร็จ
) else (
    echo ✓ พบ nuget.exe แล้ว
)
echo.

echo [4/4] Restoring NuGet packages...
echo กรุณารอสักครู่ (อาจใช้เวลา 2-5 นาที)...
echo.

nuget.exe restore "Take Time BangPhra.sln" -NonInteractive

if errorlevel 1 (
    echo.
    echo ERROR: Package restore failed
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo ✓ แก้ไขเสร็จสมบูรณ์!
echo ============================================================
echo.
echo ตรวจสอบผลลัพธ์:
echo.

REM ตรวจสอบว่ามี packages folder
if exist "packages" (
    echo ✓ พบ packages folder

    if exist "packages\iTextSharp.5.5.13.3" (
        echo ✓ พบ iTextSharp package
    ) else (
        echo ✗ ไม่พบ iTextSharp package
    )

    if exist "packages\Google.Apis.Gmail.v1.1.64.0.3231" (
        echo ✓ พบ Gmail API package
    ) else (
        echo ✗ ไม่พบ Gmail API package
    )
) else (
    echo ✗ ไม่พบ packages folder
    echo กรุณาเปิด Visual Studio และ Restore NuGet Packages ด้วยตนเอง
)

echo.
echo ============================================================
echo ขั้นตอนต่อไป:
echo ============================================================
echo.
echo 1. เปิด Visual Studio
echo 2. เปิด solution: Take Time BangPhra.sln
echo 3. กด Ctrl+Shift+B เพื่อ Rebuild
echo 4. ตรวจสอบ Error List ควรเห็น 0 Errors
echo.
pause
