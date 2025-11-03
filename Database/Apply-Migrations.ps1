# ============================================================================
# Database Migration Runner for Taketime
# ============================================================================
# This script applies SQL migrations to the database automatically
# Run after: git pull
# ============================================================================

param(
    [string]$ServerName = "localhost",
    [string]$DatabaseName = "Taketime",
    [switch]$UseWindowsAuth = $true,
    [string]$Username = "",
    [string]$Password = "",
    [switch]$WhatIf = $false
)

# Configuration
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$MigrationFolder = $ScriptPath
$LogFile = Join-Path $ScriptPath "migration-log.txt"

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }

# ============================================================================
# Functions
# ============================================================================

function Test-SqlModule {
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Warning "SqlServer module not found. Installing..."
        try {
            Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
            Import-Module SqlServer
            Write-Success "✓ SqlServer module installed"
        }
        catch {
            Write-Error "✗ Failed to install SqlServer module"
            Write-Error "Please install manually: Install-Module -Name SqlServer"
            exit 1
        }
    }
    else {
        Import-Module SqlServer -ErrorAction SilentlyContinue
    }
}

function Get-ConnectionString {
    if ($UseWindowsAuth) {
        return "Server=$ServerName;Database=$DatabaseName;Integrated Security=True;TrustServerCertificate=True"
    }
    else {
        return "Server=$ServerName;Database=$DatabaseName;User Id=$Username;Password=$Password;TrustServerCertificate=True"
    }
}

function Test-DatabaseConnection {
    param([string]$ConnectionString)

    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Get-AppliedMigrations {
    param([string]$ConnectionString)

    $query = "SELECT MigrationName FROM Database_Migrations WHERE Success = 1"

    try {
        $result = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $query -ErrorAction Stop
        return $result | Select-Object -ExpandProperty MigrationName
    }
    catch {
        # Migration table doesn't exist yet
        return @()
    }
}

function Invoke-Migration {
    param(
        [string]$ConnectionString,
        [string]$MigrationFile,
        [string]$MigrationName
    )

    Write-Info "  Applying: $MigrationName"

    if ($WhatIf) {
        Write-Warning "  [WhatIf] Would apply migration: $MigrationName"
        return $true
    }

    $scriptContent = Get-Content $MigrationFile -Raw
    $startTime = Get-Date

    try {
        # Execute the migration script
        Invoke-Sqlcmd -ConnectionString $ConnectionString -InputFile $MigrationFile -ErrorAction Stop -Verbose:$false

        $endTime = Get-Date
        $executionTime = [int](($endTime - $startTime).TotalMilliseconds)

        # Record successful migration
        $recordQuery = @"
EXEC sp_RecordMigration
    @MigrationName = '$MigrationName',
    @AppliedBy = '$env:USERNAME',
    @Success = 1,
    @ExecutionTimeMs = $executionTime
"@

        Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $recordQuery -ErrorAction Stop

        Write-Success "  ✓ Success ($executionTime ms)"

        # Log to file
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | SUCCESS | $MigrationName | $executionTime ms"
        Add-Content -Path $LogFile -Value $logEntry

        return $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "  ✗ Failed: $errorMessage"

        # Record failed migration
        $recordQuery = @"
EXEC sp_RecordMigration
    @MigrationName = '$MigrationName',
    @AppliedBy = '$env:USERNAME',
    @Success = 0,
    @ErrorMessage = '$($errorMessage -replace "'", "''")'
"@

        try {
            Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $recordQuery -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore errors when recording failure
        }

        # Log to file
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FAILED | $MigrationName | $errorMessage"
        Add-Content -Path $LogFile -Value $logEntry

        return $false
    }
}

# ============================================================================
# Main Script
# ============================================================================

Clear-Host

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Taketime Database Migration Runner" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check for SQL Server module
Write-Info "Checking prerequisites..."
Test-SqlModule

# Build connection string
$connectionString = Get-ConnectionString

Write-Info "Database: $DatabaseName on $ServerName"
Write-Info "User: $(if ($UseWindowsAuth) { 'Windows Authentication' } else { $Username })"

if ($WhatIf) {
    Write-Warning "Running in WhatIf mode - no changes will be made"
}

Write-Host ""

# Test connection
Write-Info "Testing database connection..."
if (-not (Test-DatabaseConnection $connectionString)) {
    Write-Error "✗ Cannot connect to database"
    Write-Error "Please check:"
    Write-Error "  - SQL Server is running"
    Write-Error "  - Database exists"
    Write-Error "  - Connection credentials are correct"
    exit 1
}
Write-Success "✓ Connected successfully"
Write-Host ""

# Get list of migration files (sorted by filename)
$migrationFiles = Get-ChildItem -Path $MigrationFolder -Filter "*.sql" |
    Where-Object { $_.Name -notlike "Taketime_Database_Schema.sql" } |
    Sort-Object Name

if ($migrationFiles.Count -eq 0) {
    Write-Warning "No migration files found in: $MigrationFolder"
    exit 0
}

Write-Info "Found $($migrationFiles.Count) migration file(s)"
Write-Host ""

# Get already applied migrations
$appliedMigrations = Get-AppliedMigrations $connectionString

if ($appliedMigrations.Count -gt 0) {
    Write-Info "Already applied: $($appliedMigrations.Count) migration(s)"
}

Write-Host ""
Write-Info "Applying pending migrations..."
Write-Host ""

$pendingCount = 0
$successCount = 0
$failCount = 0

foreach ($file in $migrationFiles) {
    $migrationName = $file.Name -replace '\.sql$', ''

    # Check if already applied
    if ($appliedMigrations -contains $migrationName) {
        Write-Host "  $migrationName" -ForegroundColor DarkGray -NoNewline
        Write-Host " [SKIPPED - Already applied]" -ForegroundColor DarkGray
        continue
    }

    $pendingCount++

    # Apply migration
    $success = Invoke-Migration -ConnectionString $connectionString -MigrationFile $file.FullName -MigrationName $migrationName

    if ($success) {
        $successCount++
    }
    else {
        $failCount++

        # Ask if should continue
        Write-Host ""
        $response = Read-Host "Migration failed. Continue with remaining migrations? (y/n)"
        if ($response -ne 'y') {
            Write-Warning "Migration process aborted by user"
            break
        }
        Write-Host ""
    }
}

# Summary
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Migration Summary" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total files:      $($migrationFiles.Count)"
Write-Host "  Already applied:  $($appliedMigrations.Count)"
Write-Host "  Pending:          $pendingCount"
Write-Success "  Success:          $successCount"
if ($failCount -gt 0) {
    Write-Error "  Failed:           $failCount"
}
Write-Host ""

if ($WhatIf) {
    Write-Warning "This was a WhatIf run - no changes were made"
    Write-Host ""
}

# Show migration history
if (-not $WhatIf -and $successCount -gt 0) {
    Write-Info "Recent migration history:"
    Write-Host ""

    $historyQuery = "SELECT TOP 5 * FROM v_MigrationHistory ORDER BY AppliedDate DESC"
    $history = Invoke-Sqlcmd -ConnectionString $connectionString -Query $historyQuery

    $history | Format-Table -Property MigrationName, AppliedDate, AppliedBy, Status, ExecutionTimeMs -AutoSize
}

Write-Host "Log file: $LogFile"
Write-Host ""

if ($failCount -eq 0 -and $successCount -gt 0) {
    Write-Success "All migrations applied successfully!"
    exit 0
}
elseif ($failCount -gt 0) {
    Write-Error "Some migrations failed. Please check the log file."
    exit 1
}
else {
    Write-Info "No new migrations to apply."
    exit 0
}
