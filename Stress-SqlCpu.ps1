<#
.SYNOPSIS
    Safe SQL Server CPU stress test script with failsafe mechanisms.

.DESCRIPTION
    This script increases SQL Server CPU utilization to a specified target percentage.
    Includes multiple failsafe mechanisms:
    - Maximum runtime limit
    - Emergency stop file monitoring
    - Ctrl+C graceful shutdown
    - Automatic cleanup on exit
    - Resource validation before start

.PARAMETER TargetCpuPercent
    Target CPU utilization percentage (1-95). Default is 70%.

.PARAMETER DurationMinutes
    Maximum duration to run the test in minutes. Default is 5 minutes.

.PARAMETER SqlInstance
    SQL Server instance name. Default is localhost.

.PARAMETER Database
    Database to use for stress test. Default is tempdb.

.PARAMETER EmergencyStopFile
    Path to emergency stop file. If this file exists, script stops immediately.

.EXAMPLE
    .\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 10

.EXAMPLE
    .\Stress-SqlCpu.ps1 -TargetCpuPercent 80 -DurationMinutes 5 -SqlInstance "SERVER\INSTANCE"

.NOTES
    Author: System Administrator
    Safety Features:
    - Maximum CPU target capped at 95%
    - Auto-stop after duration limit
    - Emergency stop file monitoring
    - Graceful cleanup on exit
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(1, 95)]
    [int]$TargetCpuPercent = 70,

    [Parameter()]
    [ValidateRange(1, 60)]
    [int]$DurationMinutes = 5,

    [Parameter()]
    [string]$SqlInstance = "localhost",

    [Parameter()]
    [string]$Database = "tempdb",

    [Parameter()]
    [string]$EmergencyStopFile = "$PSScriptRoot\STOP_SQL_STRESS.txt"
)

# Safety validation
if ($TargetCpuPercent -gt 95) {
    Write-Error "Target CPU cannot exceed 95% for safety reasons"
    exit 1
}

# Global variables for cleanup
$global:StressJobs = @()
$global:SqlConnections = @()
$global:IsRunning = $true

# Cleanup function
function Stop-StressTest {
    param([string]$Reason = "Unknown")
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Stopping stress test... Reason: $Reason" -ForegroundColor Yellow
    $global:IsRunning = $false
    
    # Stop all background jobs
    if ($global:StressJobs.Count -gt 0) {
        Write-Host "Stopping $($global:StressJobs.Count) worker jobs..." -ForegroundColor Yellow
        $global:StressJobs | Stop-Job -ErrorAction SilentlyContinue
        $global:StressJobs | Remove-Job -Force -ErrorAction SilentlyContinue
        $global:StressJobs = @()
    }
    
    # Close SQL connections
    if ($global:SqlConnections.Count -gt 0) {
        Write-Host "Closing SQL connections..." -ForegroundColor Yellow
        foreach ($conn in $global:SqlConnections) {
            if ($conn.State -eq 'Open') {
                $conn.Close()
            }
            $conn.Dispose()
        }
        $global:SqlConnections = @()
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Cleanup completed" -ForegroundColor Green
}

# Register cleanup handlers
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-StressTest -Reason "PowerShell exiting"
} | Out-Null

# Ctrl+C handler
$null = [Console]::TreatControlCAsInput = $false
try {
    [Console]::CancelKeyPress.Add({
        param($sender, $e)
        $e.Cancel = $true
        Stop-StressTest -Reason "Ctrl+C pressed"
    })
} catch {
    Write-Warning "Could not register Ctrl+C handler: $_"
}

# Function to test SQL connection
function Test-SqlConnection {
    param([string]$Instance, [string]$Db)
    
    try {
        $connString = "Server=$Instance;Database=$Db;Integrated Security=True;Connection Timeout=5;"
        $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
        $conn.Open()
        $conn.Close()
        $conn.Dispose()
        return $true
    } catch {
        Write-Error "Cannot connect to SQL Server '$Instance': $_"
        return $false
    }
}

# CPU stress query generator
function Get-CpuStressQuery {
    return @"
DECLARE @EndTime DATETIME = DATEADD(SECOND, 30, GETDATE());
DECLARE @Counter BIGINT = 0;

-- CPU-intensive calculation loop
WHILE GETDATE() < @EndTime
BEGIN
    SET @Counter = @Counter + 1;
    
    -- Prime number check (CPU intensive)
    DECLARE @Num INT = @Counter % 10000 + 1;
    DECLARE @IsPrime BIT = 1;
    DECLARE @i INT = 2;
    
    WHILE @i <= SQRT(@Num) AND @IsPrime = 1
    BEGIN
        IF @Num % @i = 0
            SET @IsPrime = 0;
        SET @i = @i + 1;
    END
    
    -- Hash calculation (CPU intensive)
    DECLARE @Hash VARBINARY(32) = HASHBYTES('SHA2_256', CAST(@Counter AS VARCHAR(20)));
    
    -- Prevent query timeout
    IF @Counter % 1000 = 0
        WAITFOR DELAY '00:00:00.001';
END

SELECT @Counter AS IterationsCompleted;
"@
}

# Main script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SQL Server CPU Stress Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target CPU:     $TargetCpuPercent%" -ForegroundColor White
Write-Host "Duration:       $DurationMinutes minutes" -ForegroundColor White
Write-Host "SQL Instance:   $SqlInstance" -ForegroundColor White
Write-Host "Database:       $Database" -ForegroundColor White
Write-Host "Emergency Stop: $EmergencyStopFile" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

# Validate SQL connection
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Validating SQL Server connection..." -ForegroundColor Yellow
if (-not (Test-SqlConnection -Instance $SqlInstance -Db $Database)) {
    Stop-StressTest -Reason "SQL connection failed"
    exit 1
}
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Connection successful`n" -ForegroundColor Green

# Calculate number of workers needed (rough estimate)
$LogicalProcessors = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
$WorkerCount = [Math]::Max(1, [Math]::Floor($LogicalProcessors * ($TargetCpuPercent / 100.0)))
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting $WorkerCount worker threads..." -ForegroundColor Yellow

# Create emergency stop file info
Write-Host "`nEmergency Stop Instructions:" -ForegroundColor Red
Write-Host "  1. Press Ctrl+C, OR" -ForegroundColor Yellow
Write-Host "  2. Create file: $EmergencyStopFile" -ForegroundColor Yellow
Write-Host ""

# Start worker jobs
$StressQuery = Get-CpuStressQuery
for ($i = 1; $i -le $WorkerCount; $i++) {
    $job = Start-Job -ScriptBlock {
        param($Instance, $Db, $Query)
        
        $connString = "Server=$Instance;Database=$Db;Integrated Security=True;Connection Timeout=30;"
        
        while ($true) {
            try {
                $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
                $conn.Open()
                
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $Query
                $cmd.CommandTimeout = 60
                
                $null = $cmd.ExecuteScalar()
                
                $cmd.Dispose()
                $conn.Close()
                $conn.Dispose()
            } catch {
                Start-Sleep -Milliseconds 100
            }
        }
    } -ArgumentList $SqlInstance, $Database, $StressQuery
    
    $global:StressJobs += $job
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Worker $i started (Job ID: $($job.Id))" -ForegroundColor Green
}

# Monitor and maintain stress
$StartTime = Get-Date
$EndTime = $StartTime.AddMinutes($DurationMinutes)
$LastCheck = $StartTime

Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Stress test running... (Will stop at $($EndTime.ToString('HH:mm:ss')))`n" -ForegroundColor Cyan

while ($global:IsRunning) {
    $CurrentTime = Get-Date
    
    # Check duration limit
    if ($CurrentTime -ge $EndTime) {
        Stop-StressTest -Reason "Duration limit reached"
        break
    }
    
    # Check emergency stop file
    if (Test-Path $EmergencyStopFile) {
        Remove-Item $EmergencyStopFile -Force
        Stop-StressTest -Reason "Emergency stop file detected"
        break
    }
    
    # Display status every 10 seconds
    if (($CurrentTime - $LastCheck).TotalSeconds -ge 10) {
        $ElapsedMinutes = [Math]::Round(($CurrentTime - $StartTime).TotalMinutes, 1)
        $RemainingMinutes = [Math]::Round(($EndTime - $CurrentTime).TotalMinutes, 1)
        
        try {
            # Get SQL Server CPU usage
            $connString = "Server=$SqlInstance;Database=$Database;Integrated Security=True;Connection Timeout=5;"
            $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
            $conn.Open()
            
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = @"
SELECT TOP 1 
    AVG([SQLProcessUtilization]) as SqlCpuPercent
FROM (
    SELECT TOP 30
        [SQLProcessUtilization]
    FROM (
        SELECT 
            record.value('(./Record/@id)[1]', 'int') AS record_id,
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle],
            record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [SQLProcessUtilization]
        FROM (
            SELECT [timestamp], CONVERT(xml, record) AS [record] 
            FROM sys.dm_os_ring_buffers WITH (NOLOCK)
            WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
            AND record LIKE N'%<SystemHealth>%'
        ) AS x
    ) AS y
    ORDER BY record_id DESC
) AS Recent;
"@
            $reader = $cmd.ExecuteReader()
            if ($reader.Read()) {
                $SqlCpu = [Math]::Round($reader["SqlCpuPercent"], 1)
                $reader.Close()
                
                $StatusColor = if ($SqlCpu -ge ($TargetCpuPercent - 5)) { "Green" } elseif ($SqlCpu -ge ($TargetCpuPercent - 15)) { "Yellow" } else { "Red" }
                
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor White
                Write-Host "SQL CPU: $SqlCpu% " -NoNewline -ForegroundColor $StatusColor
                Write-Host "| Target: $TargetCpuPercent% " -NoNewline -ForegroundColor White
                Write-Host "| Elapsed: $ElapsedMinutes min " -NoNewline -ForegroundColor White
                Write-Host "| Remaining: $RemainingMinutes min" -ForegroundColor White
            } else {
                $reader.Close()
            }
            
            $conn.Close()
            $conn.Dispose()
        } catch {
            Write-Warning "Could not retrieve CPU stats: $_"
        }
        
        $LastCheck = $CurrentTime
    }
    
    Start-Sleep -Milliseconds 500
}

# Final status
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Stress Test Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$TotalRuntime = [Math]::Round(((Get-Date) - $StartTime).TotalMinutes, 2)
Write-Host "Total Runtime: $TotalRuntime minutes" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

exit 0