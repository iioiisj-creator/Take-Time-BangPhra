# Restore NuGet Packages Script
# Run this in PowerShell or Command Prompt

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Restoring NuGet Packages for Take Time BangPhra Project" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if nuget.exe exists
$nugetPath = ".\nuget.exe"
$nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

if (-Not (Test-Path $nugetPath)) {
    Write-Host "NuGet.exe not found. Downloading..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath
        Write-Host "✓ Downloaded nuget.exe successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to download nuget.exe" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please download nuget.exe manually from:" -ForegroundColor Yellow
        Write-Host "https://www.nuget.org/downloads" -ForegroundColor Yellow
        Write-Host "And place it in the solution root folder." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Restoring packages..." -ForegroundColor Yellow
Write-Host ""

# Navigate to solution directory
$solutionPath = "Take Time BangPhra.sln"

if (Test-Path $solutionPath) {
    # Restore packages
    & $nugetPath restore $solutionPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=============================================================" -ForegroundColor Green
        Write-Host "✓ Package restoration completed successfully!" -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Open the solution in Visual Studio" -ForegroundColor White
        Write-Host "2. Build the solution (Ctrl+Shift+B)" -ForegroundColor White
        Write-Host "3. All errors should be resolved" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "✗ Package restoration failed!" -ForegroundColor Red
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✗ Solution file not found: $solutionPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please make sure you're running this script from the solution root directory." -ForegroundColor Yellow
    exit 1
}
