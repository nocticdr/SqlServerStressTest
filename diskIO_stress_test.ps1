<#
.SYNOPSIS
    Safe disk I/O stress test script with failsafe mechanisms.

.DESCRIPTION
    This script stresses disk I/O by performing intensive read/write operations.
    Includes multiple failsafe mechanisms:
    - Maximum runtime limit
    - Emergency stop file monitoring
    - Ctrl+C graceful shutdown
    - Automatic cleanup on exit
    - Disk space validation before start
    - Configurable I/O patterns (read, write, or mixed)

.PARAMETER TargetIOType
    Type of I/O to perform: Read, Write, or Mixed. Default is Mixed.

.PARAMETER DurationMinutes
    Maximum duration to run the test in minutes. Default is 5 minutes.

.PARAMETER TestPath
    Path where test files will be created. Default is C:\DiskStressTest.

.PARAMETER FileSizeGB
    Size of each test file in GB. Default is 1 GB.

.PARAMETER ThreadCount
    Number of parallel I/O threads. Default is 4. Range: 1-16.

.PARAMETER BlockSizeKB
    I/O block size in KB. Default is 64 KB. Common: 4, 8, 64, 256, 1024.

.PARAMETER EmergencyStopFile
    Path to emergency stop file. If this file exists, script stops immediately.

.PARAMETER SkipSpaceCheck
    Skip the disk space validation check (not recommended).

.EXAMPLE
    .\Stress-DiskIO.ps1 -TargetIOType Mixed -DurationMinutes 10

.EXAMPLE
    .\Stress-DiskIO.ps1 -TargetIOType Write -FileSizeGB 2 -ThreadCount 8

.EXAMPLE
    .\Stress-DiskIO.ps1 -TargetIOType Read -TestPath "D:\Test" -DurationMinutes 15

.NOTES
    Author: System Administrator
    Safety Features:
    - Validates disk space before start
    - Auto-stop after duration limit
    - Emergency stop file monitoring
    - Graceful cleanup on exit
    - Automatic file deletion
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Read", "Write", "Mixed")]
    [string]$TargetIOType = "Mixed",

    [Parameter()]
    [ValidateRange(1, 120)]
    [int]$DurationMinutes = 5,

    [Parameter()]
    [string]$TestPath = "C:\DiskStressTest",

    [Parameter()]
    [ValidateRange(0.1, 100)]
    [double]$FileSizeGB = 1,

    [Parameter()]
    [ValidateRange(1, 16)]
    [int]$ThreadCount = 4,

    [Parameter()]
    [ValidateSet(4, 8, 16, 32, 64, 128, 256, 512, 1024)]
    [int]$BlockSizeKB = 64,

    [Parameter()]
    [string]$EmergencyStopFile = "$PSScriptRoot\STOP_DISK_STRESS.txt",

    [Parameter()]
    [switch]$SkipSpaceCheck
)

# Global variables for cleanup
$global:StressJobs = @()
$global:TestFiles = @()
$global:IsRunning = $true
$global:TotalBytesRead = 0
$global:TotalBytesWritten = 0

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
    
    # Clean up test files
    if ($global:TestFiles.Count -gt 0) {
        Write-Host "Removing $($global:TestFiles.Count) test files..." -ForegroundColor Yellow
        foreach ($file in $global:TestFiles) {
            if (Test-Path $file) {
                try {
                    Remove-Item $file -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Warning "Could not remove file: $file"
                }
            }
        }
        $global:TestFiles = @()
    }
    
    # Remove test directory if empty
    if (Test-Path $TestPath) {
        $items = Get-ChildItem $TestPath -ErrorAction SilentlyContinue
        if ($items.Count -eq 0) {
            Remove-Item $TestPath -Force -ErrorAction SilentlyContinue
        }
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

# Function to validate disk space
function Test-DiskSpace {
    param(
        [string]$Path,
        [double]$RequiredGB
    )
    
    try {
        $drive = (Get-Item $Path -ErrorAction Stop).PSDrive
        if (-not $drive) {
            $drive = [System.IO.Path]::GetPathRoot($Path)
            $volume = Get-Volume -DriveLetter $drive[0] -ErrorAction Stop
            $freeSpaceGB = $volume.SizeRemaining / 1GB
        } else {
            $freeSpaceGB = $drive.Free / 1GB
        }
        
        Write-Host "Available space on drive: $([Math]::Round($freeSpaceGB, 2)) GB" -ForegroundColor Cyan
        Write-Host "Required space: $([Math]::Round($RequiredGB, 2)) GB" -ForegroundColor Cyan
        
        if ($freeSpaceGB -lt $RequiredGB) {
            Write-Error "Insufficient disk space. Required: $RequiredGB GB, Available: $([Math]::Round($freeSpaceGB, 2)) GB"
            return $false
        }
        
        # Require 20% buffer
        $requiredWithBuffer = $RequiredGB * 1.2
        if ($freeSpaceGB -lt $requiredWithBuffer) {
            Write-Warning "Low disk space. Recommended: $([Math]::Round($requiredWithBuffer, 2)) GB (20% buffer), Available: $([Math]::Round($freeSpaceGB, 2)) GB"
            $response = Read-Host "Continue anyway? (yes/no)"
            if ($response -ne "yes") {
                return $false
            }
        }
        
        return $true
    } catch {
        Write-Error "Could not validate disk space: $_"
        return $false
    }
}

# Function to format bytes
function Format-Bytes {
    param([long]$Bytes)
    
    if ($Bytes -ge 1TB) {
        return "$([Math]::Round($Bytes / 1TB, 2)) TB"
    } elseif ($Bytes -ge 1GB) {
        return "$([Math]::Round($Bytes / 1GB, 2)) GB"
    } elseif ($Bytes -ge 1MB) {
        return "$([Math]::Round($Bytes / 1MB, 2)) MB"
    } elseif ($Bytes -ge 1KB) {
        return "$([Math]::Round($Bytes / 1KB, 2)) KB"
    } else {
        return "$Bytes Bytes"
    }
}

# Function to get disk performance counters
function Get-DiskPerformance {
    param([string]$DriveLetter)
    
    try {
        $disk = Get-Counter "\PhysicalDisk(*)\Disk Reads/sec", "\PhysicalDisk(*)\Disk Writes/sec" -ErrorAction SilentlyContinue
        
        $totalReads = 0
        $totalWrites = 0
        
        foreach ($sample in $disk.CounterSamples) {
            if ($sample.Path -like "*_Total*") {
                if ($sample.Path -like "*Reads/sec*") {
                    $totalReads = [Math]::Round($sample.CookedValue, 2)
                } elseif ($sample.Path -like "*Writes/sec*") {
                    $totalWrites = [Math]::Round($sample.CookedValue, 2)
                }
            }
        }
        
        return @{
            ReadsPerSec = $totalReads
            WritesPerSec = $totalWrites
            TotalIOPS = $totalReads + $totalWrites
        }
    } catch {
        return @{
            ReadsPerSec = 0
            WritesPerSec = 0
            TotalIOPS = 0
        }
    }
}

# Main script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Disk I/O Stress Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "I/O Type:       $TargetIOType" -ForegroundColor White
Write-Host "Duration:       $DurationMinutes minutes" -ForegroundColor White
Write-Host "Test Path:      $TestPath" -ForegroundColor White
Write-Host "File Size:      $FileSizeGB GB per file" -ForegroundColor White
Write-Host "Thread Count:   $ThreadCount" -ForegroundColor White
Write-Host "Block Size:     $BlockSizeKB KB" -ForegroundColor White
Write-Host "Emergency Stop: $EmergencyStopFile" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

# Create test directory
if (-not (Test-Path $TestPath)) {
    try {
        New-Item -ItemType Directory -Path $TestPath -Force | Out-Null
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Created test directory: $TestPath" -ForegroundColor Green
    } catch {
        Write-Error "Could not create test directory: $_"
        exit 1
    }
}

# Validate disk space
if (-not $SkipSpaceCheck) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Validating disk space..." -ForegroundColor Yellow
    $requiredSpace = $FileSizeGB * $ThreadCount
    if (-not (Test-DiskSpace -Path $TestPath -RequiredGB $requiredSpace)) {
        Stop-StressTest -Reason "Insufficient disk space"
        exit 1
    }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Disk space validation passed`n" -ForegroundColor Green
}

# Create emergency stop file info
Write-Host "Emergency Stop Instructions:" -ForegroundColor Red
Write-Host "  1. Press Ctrl+C, OR" -ForegroundColor Yellow
Write-Host "  2. Create file: $EmergencyStopFile" -ForegroundColor Yellow
Write-Host ""

# Calculate file size in bytes
$FileSizeBytes = [long]($FileSizeGB * 1GB)
$BlockSizeBytes = $BlockSizeKB * 1KB

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Creating and initializing test files..." -ForegroundColor Yellow

# Create test files for each thread
for ($i = 1; $i -le $ThreadCount; $i++) {
    $fileName = Join-Path $TestPath "stresstest_$i.dat"
    $global:TestFiles += $fileName
    
    # Create file with random data
    try {
        $file = [System.IO.File]::Create($fileName)
        $buffer = New-Object byte[] $BlockSizeBytes
        $random = New-Object System.Random
        
        $bytesWritten = 0
        while ($bytesWritten -lt $FileSizeBytes) {
            $random.NextBytes($buffer)
            $writeSize = [Math]::Min($BlockSizeBytes, $FileSizeBytes - $bytesWritten)
            $file.Write($buffer, 0, $writeSize)
            $bytesWritten += $writeSize
        }
        
        $file.Close()
        $file.Dispose()
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Created test file $i`: $fileName ($FileSizeGB GB)" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create test file: $_"
        Stop-StressTest -Reason "File creation failed"
        exit 1
    }
}

Write-Host ""

# Start worker jobs based on I/O type
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting $ThreadCount worker threads ($TargetIOType I/O)..." -ForegroundColor Yellow

for ($i = 0; $i -lt $ThreadCount; $i++) {
    $fileName = $global:TestFiles[$i]
    
    $job = Start-Job -ScriptBlock {
        param($FilePath, $IOType, $BlockSize, $FileSize)
        
        $buffer = New-Object byte[] $BlockSize
        $random = New-Object System.Random
        $bytesProcessed = 0
        
        while ($true) {
            try {
                if ($IOType -eq "Read" -or ($IOType -eq "Mixed" -and (Get-Random -Minimum 0 -Maximum 2) -eq 0)) {
                    # Read operation
                    $file = [System.IO.File]::OpenRead($FilePath)
                    $position = Get-Random -Minimum 0 -Maximum ([Math]::Max(0, $FileSize - $BlockSize))
                    $file.Seek($position, [System.IO.SeekOrigin]::Begin) | Out-Null
                    $bytesRead = $file.Read($buffer, 0, $BlockSize)
                    $file.Close()
                    $file.Dispose()
                    $bytesProcessed += $bytesRead
                } else {
                    # Write operation
                    $file = [System.IO.File]::OpenWrite($FilePath)
                    $position = Get-Random -Minimum 0 -Maximum ([Math]::Max(0, $FileSize - $BlockSize))
                    $file.Seek($position, [System.IO.SeekOrigin]::Begin) | Out-Null
                    $random.NextBytes($buffer)
                    $file.Write($buffer, 0, $BlockSize)
                    $file.Flush()
                    $file.Close()
                    $file.Dispose()
                    $bytesProcessed += $BlockSize
                }
            } catch {
                Start-Sleep -Milliseconds 10
            }
        }
    } -ArgumentList $fileName, $TargetIOType, $BlockSizeBytes, $FileSizeBytes
    
    $global:StressJobs += $job
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Worker $($i + 1) started (Job ID: $($job.Id))" -ForegroundColor Green
}

# Monitor and maintain stress
$StartTime = Get-Date
$EndTime = $StartTime.AddMinutes($DurationMinutes)
$LastCheck = $StartTime
$LastBytes = @{ Read = 0; Write = 0 }

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
    
    # Display status every 5 seconds
    if (($CurrentTime - $LastCheck).TotalSeconds -ge 5) {
        $ElapsedMinutes = [Math]::Round(($CurrentTime - $StartTime).TotalMinutes, 1)
        $RemainingMinutes = [Math]::Round(($EndTime - $CurrentTime).TotalMinutes, 1)
        
        try {
            $diskPerf = Get-DiskPerformance -DriveLetter $TestPath[0]
            
            $statusColor = if ($diskPerf.TotalIOPS -ge 100) { "Green" } elseif ($diskPerf.TotalIOPS -ge 50) { "Yellow" } else { "Red" }
            
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor White
            Write-Host "IOPS: $($diskPerf.TotalIOPS) " -NoNewline -ForegroundColor $statusColor
            Write-Host "(R: $($diskPerf.ReadsPerSec) W: $($diskPerf.WritesPerSec)) " -NoNewline -ForegroundColor White
            Write-Host "| Elapsed: $ElapsedMinutes min " -NoNewline -ForegroundColor White
            Write-Host "| Remaining: $RemainingMinutes min " -NoNewline -ForegroundColor White
            Write-Host "| Threads: $ThreadCount" -ForegroundColor White
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor White
            Write-Host "Elapsed: $ElapsedMinutes min | Remaining: $RemainingMinutes min" -ForegroundColor White
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
Write-Host "Files Created: $ThreadCount" -ForegroundColor White
Write-Host "Total Data Size: $(Format-Bytes ($FileSizeBytes * $ThreadCount))" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

exit 0