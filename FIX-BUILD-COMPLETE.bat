@echo off
echo ============================================
echo   แก้ไข Build Errors อัตโนมัติ (ฉบับสมบูรณ์)
echo ============================================
echo.

echo [1/6] กำลังบันทึกการเปลี่ยนแปลงปัจจุบัน...
git stash
echo.

echo [2/6] กำลัง Pull โค้ดล่าสุดจาก Git...
git fetch origin
git checkout claude/create-taketime-database-011CUkLZUbuJ3mg2G17MacRS
git pull origin claude/create-taketime-database-011CUkLZUbuJ3mg2G17MacRS
echo.

echo [3/6] กำลังตรวจสอบไฟล์ CheckDocument.aspx.cs...
echo ค้นหา GetCategoryDisplayName...
findstr /N /C:"GetCategoryDisplayName" "Take Time BangPhra\Account\CheckDocument.aspx.cs" | find "220"
if %errorlevel% equ 0 (
    echo   ✓ พบ GetCategoryDisplayName ที่บรรทัด 220
) else (
    echo   ✗ ไม่พบ GetCategoryDisplayName ที่บรรทัด 220 - มีปัญหา!
)
echo.

echo [4/6] กำลังลบไฟล์ Bin และ Obj...
if exist "Take Time BangPhra\bin" rd /s /q "Take Time BangPhra\bin"
if exist "Take Time BangPhra\obj" rd /s /q "Take Time BangPhra\obj"
echo   ✓ ลบไฟล์ Bin และ Obj เรียบร้อย
echo.

echo [5/6] กำลัง Restore NuGet Packages...
if not exist nuget.exe (
    echo   กำลังดาวน์โหลด nuget.exe...
    powershell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'nuget.exe'"
)
nuget.exe restore "Take Time BangPhra.sln"
echo.

echo [6/6] ตรวจสอบข้อมูลสำคัญ...
echo.
echo === สถานะ Git ===
git status
echo.
echo === Commits ล่าสุด ===
git log --oneline -3
echo.

echo ============================================
echo   เสร็จสิ้น!
echo ============================================
echo.
echo ขั้นตอนถัดไป:
echo 1. เปิด Visual Studio
echo 2. กด Ctrl+Shift+B เพื่อ Rebuild Solution
echo 3. ตรวจสอบ Error List
echo.
echo หากยังคงมี Error ให้ส่ง error message มาให้ผม
echo.
pause
