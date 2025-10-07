# Disk I/O Stress Test Script

A safe and controlled PowerShell script for testing disk I/O performance with built-in failsafe mechanisms. Perfect for testing storage systems, monitoring alerts, backup performance, and I/O bottlenecks.

## Table of Contents
- [Overview](#overview)
- [Safety Features](#safety-features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Parameters](#parameters)
- [Usage Examples](#usage-examples)
- [How It Works](#how-it-works)
- [Emergency Stop Procedures](#emergency-stop-procedures)
- [Monitoring Output](#monitoring-output)
- [I/O Patterns Explained](#io-patterns-explained)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Performance Tuning](#performance-tuning)

## Overview

This script generates intensive disk I/O to test storage performance, monitoring systems, and infrastructure limits. It supports three I/O patterns:

- **Read** - Sequential and random read operations
- **Write** - Sequential and random write operations  
- **Mixed** - Realistic combination of reads and writes

**Key Point:** This script creates temporary test files but does not affect existing data. All test files are automatically cleaned up on exit.

## Safety Features

### 🛡️ Multiple Failsafes

1. **Disk Space Validation** - Checks available space before starting
2. **20% Buffer Requirement** - Ensures disk won't fill completely
3. **Time-Based Auto-Stop** - Maximum 120 minutes runtime
4. **Emergency Stop File** - Instant stop by creating a trigger file
5. **Ctrl+C Handler** - Graceful shutdown with cleanup
6. **Automatic Cleanup** - Removes all test files on exit
7. **Thread Limits** - Maximum 16 threads to prevent overload
8. **Isolated Test Directory** - Files created in dedicated folder

### 🔒 What It Doesn't Do

- ❌ Does NOT modify existing files
- ❌ Does NOT fill your entire disk
- ❌ Does NOT run indefinitely
- ❌ Does NOT affect system files
- ❌ Does NOT require administrator rights (unless system drive)
- ❌ Does NOT leave files behind after exit

## Prerequisites

### Required
- Windows PowerShell 5.1 or later (or PowerShell Core 7+)
- Sufficient disk space (file size × thread count + 20% buffer)
- Write permissions to test directory

### Recommended
- Performance Monitor (perfmon) for detailed metrics
- Resource Monitor for real-time I/O monitoring
- Administrator rights for accurate performance counters

### Disk Space Requirements

Calculate required space:
```
Required Space = (FileSizeGB × ThreadCount) × 1.2
```

**Examples:**
- 4 threads × 1GB files = 4.8GB required
- 8 threads × 2GB files = 19.2GB required
- 2 threads × 5GB files = 12GB required

## Quick Start

### 1. Download the Script

Save the script as `Stress-DiskIO.ps1` in a directory of your choice.

### 2. Run with Default Settings

```powershell
# Basic run: Mixed I/O, 1GB files, 4 threads, 5 minutes
.\Stress-DiskIO.ps1
```

### 3. Run with Custom Settings

```powershell
# Heavy write test: 8 threads, 2GB files, 10 minutes
.\Stress-DiskIO.ps1 -TargetIOType Write -FileSizeGB 2 -ThreadCount 8 -DurationMinutes 10
```

### 4. Stop Anytime

Press **Ctrl+C** to stop immediately with automatic cleanup.

## Parameters

### `-TargetIOType`
**Type:** String  
**Options:** Read, Write, Mixed  
**Default:** Mixed  
**Required:** No

The type of I/O operations to perform.

**Options Explained:**
- **Read** - Only performs read operations. Tests read performance, caching, and read throughput.
- **Write** - Only performs write operations. Tests write performance, disk speed, and write caching.
- **Mixed** - Randomly alternates between reads and writes. Most realistic workload pattern.

**Examples:**
```powershell
# Test read performance
.\Stress-DiskIO.ps1 -TargetIOType Read

# Test write performance
.\Stress-DiskIO.ps1 -TargetIOType Write

# Test realistic workload (default)
.\Stress-DiskIO.ps1 -TargetIOType Mixed
```

**Use Cases:**
- **Read**: Testing backup restore, file servers, read-heavy databases
- **Write**: Testing database writes, logging systems, backup operations
- **Mixed**: General performance testing, realistic workload simulation

---

### `-DurationMinutes`
**Type:** Integer  
**Range:** 1-120  
**Default:** 5  
**Required:** No

Maximum duration to run the stress test in minutes.

**Examples:**
```powershell
# Quick 2-minute test
.\Stress-DiskIO.ps1 -DurationMinutes 2

# Standard 15-minute test
.\Stress-DiskIO.ps1 -DurationMinutes 15

# Extended 60-minute test
.\Stress-DiskIO.ps1 -DurationMinutes 60
```

**Recommendations:**
- **Quick tests:** 2-5 minutes
- **Standard tests:** 10-20 minutes
- **Endurance tests:** 30-60 minutes
- **Avoid:** Tests longer than 2 hours (use monitoring tools instead)

---

### `-TestPath`
**Type:** String  
**Default:** "C:\DiskStressTest"  
**Required:** No

Directory where test files will be created.

**Examples:**
```powershell
# Test C: drive (default)
.\Stress-DiskIO.ps1 -TestPath "C:\DiskStressTest"

# Test D: drive
.\Stress-DiskIO.ps1 -TestPath "D:\IOTest"

# Test network share (not recommended)
.\Stress-DiskIO.ps1 -TestPath "\\SERVER\Share\Test"

# Test specific folder
.\Stress-DiskIO.ps1 -TestPath "E:\TempData\StressTest"
```

**Notes:**
- Directory will be created if it doesn't exist
- Must have write permissions to the path
- Path must be on the disk you want to test
- Avoid system directories (C:\Windows, C:\Program Files)
- Network paths will test network I/O, not local disk

---

### `-FileSizeGB`
**Type:** Double  
**Range:** 0.1-100  
**Default:** 1  
**Required:** No

Size of each test file in gigabytes.

**Examples:**
```powershell
# Small files - 100MB each
.\Stress-DiskIO.ps1 -FileSizeGB 0.1

# Standard - 1GB each (default)
.\Stress-DiskIO.ps1 -FileSizeGB 1

# Large files - 5GB each
.\Stress-DiskIO.ps1 -FileSizeGB 5

# Very large - 10GB each
.\Stress-DiskIO.ps1 -FileSizeGB 10
```

**Guidelines:**
- **Small (0.1-0.5 GB)**: Fast tests, minimal space, may fit in cache
- **Medium (1-2 GB)**: Good balance, bypasses most caches
- **Large (5-10 GB)**: Sustained I/O, tests true disk performance
- **Very Large (20+ GB)**: Endurance testing, requires significant space

**Total Space Used:**
```
Total = FileSizeGB × ThreadCount × 1.2 (buffer)
```

---

### `-ThreadCount`
**Type:** Integer  
**Range:** 1-16  
**Default:** 4  
**Required:** No

Number of parallel I/O worker threads.

**Examples:**
```powershell
# Single thread - sequential I/O
.\Stress-DiskIO.ps1 -ThreadCount 1

# Light load - 2 threads
.\Stress-DiskIO.ps1 -ThreadCount 2

# Moderate load - 4 threads (default)
.\Stress-DiskIO.ps1 -ThreadCount 4

# Heavy load - 8 threads
.\Stress-DiskIO.ps1 -ThreadCount 8

# Maximum - 16 threads
.\Stress-DiskIO.ps1 -ThreadCount 16
```

**Recommendations by Disk Type:**
- **HDD (spinning disk):** 2-4 threads (HDDs perform poorly with many concurrent operations)
- **SATA SSD:** 4-8 threads
- **NVMe SSD:** 8-16 threads (can handle high concurrency)
- **Network storage:** 2-4 threads (network is usually the bottleneck)

**Performance Impact:**
- More threads = Higher IOPS but also more overhead
- Too many threads on HDD = thrashing and poor performance
- SSDs benefit from higher thread counts

---

### `-BlockSizeKB`
**Type:** Integer  
**Options:** 4, 8, 16, 32, 64, 128, 256, 512, 1024  
**Default:** 64  
**Required:** No

I/O block size in kilobytes (size of each read/write operation).

**Examples:**
```powershell
# Small blocks - 4KB (database-like)
.\Stress-DiskIO.ps1 -BlockSizeKB 4

# Small blocks - 8KB (SQL Server default)
.\Stress-DiskIO.ps1 -BlockSizeKB 8

# Medium blocks - 64KB (default, general purpose)
.\Stress-DiskIO.ps1 -BlockSizeKB 64

# Large blocks - 256KB (sequential operations)
.\Stress-DiskIO.ps1 -BlockSizeKB 256

# Very large - 1MB (streaming, video)
.\Stress-DiskIO.ps1 -BlockSizeKB 1024
```

**Common Use Cases:**
| Block Size | Use Case | Example |
|------------|----------|---------|
| 4KB | Random database I/O | SQL Server OLTP |
| 8KB | SQL Server pages | SQL Server default |
| 64KB | General file I/O | File servers, backups |
| 256KB | Sequential I/O | Data warehouses |
| 1MB | Large file streaming | Video files, large transfers |

**Performance Characteristics:**
- **Small blocks (4-8KB):** Higher IOPS, more CPU overhead, better random I/O
- **Medium blocks (64-128KB):** Balanced performance
- **Large blocks (256KB-1MB):** Higher throughput, better sequential I/O, lower IOPS

---

### `-EmergencyStopFile`
**Type:** String  
**Default:** "$PSScriptRoot\STOP_DISK_STRESS.txt"  
**Required:** No

Path to the emergency stop trigger file.

**Examples:**
```powershell
# Default location (same folder as script)
.\Stress-DiskIO.ps1

# Custom location
.\Stress-DiskIO.ps1 -EmergencyStopFile "C:\Temp\STOP.txt"

# Network share
.\Stress-DiskIO.ps1 -EmergencyStopFile "\\SERVER\Share\STOP.txt"
```

**How it works:**
- Script checks for this file every 500 milliseconds
- If the file exists, script stops immediately
- File is automatically deleted when script stops
- Useful for automation or remote stop triggers

**To trigger emergency stop:**
```powershell
New-Item -Path "STOP_DISK_STRESS.txt" -ItemType File
```

---

### `-SkipSpaceCheck`
**Type:** Switch  
**Default:** False  
**Required:** No

Skip the disk space validation check before starting.

**Examples:**
```powershell
# Skip space check (not recommended)
.\Stress-DiskIO.ps1 -SkipSpaceCheck

# Normal operation with space check (recommended)
.\Stress-DiskIO.ps1
```

**⚠️ Warning:**
- Only use if you're certain you have enough space
- Script may fail mid-test if disk fills up
- Could impact system stability if system drive fills
- Not recommended for production systems

**When to use:**
- Testing on drives with complex storage configurations
- When space check fails incorrectly
- Advanced users only

## Usage Examples

### Example 1: Basic Performance Test
Quick overall disk performance check:

```powershell
.\Stress-DiskIO.ps1 -TargetIOType Mixed -DurationMinutes 5
```

### Example 2: Database Workload Simulation
Simulate SQL Server random I/O pattern:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -BlockSizeKB 8 `
    -ThreadCount 8 `
    -FileSizeGB 2 `
    -DurationMinutes 15
```

### Example 3: Backup Performance Test
Test backup write performance:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Write `
    -BlockSizeKB 256 `
    -ThreadCount 4 `
    -FileSizeGB 5 `
    -DurationMinutes 20 `
    -TestPath "E:\Backups\Test"
```

### Example 4: SSD Endurance Test
Stress test NVMe SSD:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -ThreadCount 16 `
    -BlockSizeKB 64 `
    -FileSizeGB 10 `
    -DurationMinutes 60 `
    -TestPath "D:\NVMeTest"
```

### Example 5: HDD Sequential Read Test
Test spinning disk read performance:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Read `
    -ThreadCount 2 `
    -BlockSizeKB 1024 `
    -FileSizeGB 3 `
    -DurationMinutes 10
```

### Example 6: Monitoring System Alert Test
Trigger disk I/O alerts:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Write `
    -ThreadCount 8 `
    -DurationMinutes 10
```

### Example 7: Network Storage Test
Test network share performance:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -TestPath "\\FileServer\Share\Test" `
    -ThreadCount 4 `
    -DurationMinutes 15
```

### Example 8: Small Random I/O (OLTP)
Simulate transactional database load:

```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -BlockSizeKB 4 `
    -ThreadCount 12 `
    -FileSizeGB 1 `
    -DurationMinutes 20
```

## How It Works

### Architecture

```
PowerShell Script
    ↓
Validates Disk Space (Required + 20% buffer)
    ↓
Creates Test Files (One per thread, pre-filled with random data)
    ↓
Spawns N Worker Threads
    ↓
Each Worker → Random File Position → Read or Write
    ↓
Monitors IOPS every 5 seconds
    ↓
Auto-stops after duration OR emergency trigger
    ↓
Automatic cleanup (delete files, remove directory)
```

### File Creation Process

1. **Creates test directory** if it doesn't exist
2. **Validates disk space** (total needed + 20% buffer)
3. **Creates files** with random data to prevent compression
4. **Pre-allocates full size** to ensure consistent testing

### Worker Thread Operations

Each worker thread continuously:

1. **Opens file** for reading or writing
2. **Seeks to random position** in the file
3. **Performs I/O operation** (read or write block)
4. **Closes file** and repeats

**Read Operations:**
```
Open File → Seek Random Position → Read Block → Close
```

**Write Operations:**
```
Open File → Seek Random Position → Write Block → Flush → Close
```

**Mixed Operations:**
```
Random choice: 50% Read, 50% Write
```

### I/O Pattern

- **Random I/O:** Seeks to random positions in files
- **Block-based:** Reads/writes in consistent block sizes
- **Continuous:** Loops indefinitely until stopped
- **No caching:** Opens/closes files to bypass caching

### Performance Monitoring

The script monitors disk performance using Windows Performance Counters:

```
\PhysicalDisk(*)\Disk Reads/sec
\PhysicalDisk(*)\Disk Writes/sec
```

**Metrics Displayed:**
- **IOPS:** Total I/O operations per second
- **Reads/sec:** Read operations per second
- **Writes/sec:** Write operations per second
- **Elapsed/Remaining:** Time tracking

## Emergency Stop Procedures

### Method 1: Ctrl+C (Recommended)

Simply press `Ctrl+C` in the PowerShell window.

**What happens:**
1. Graceful shutdown initiated
2. All worker threads stopped
3. Test files deleted
4. Test directory removed (if empty)
5. Final status displayed

**Cleanup time:** 2-5 seconds typically

---

### Method 2: Emergency Stop File

Create the emergency stop file to trigger immediate shutdown.

**From PowerShell:**
```powershell
New-Item -Path "STOP_DISK_STRESS.txt" -ItemType File
```

**From Command Prompt:**
```cmd
echo. > STOP_DISK_STRESS.txt
```

**From another machine:**
```powershell
New-Item -Path "\\SERVER\C$\Scripts\STOP_DISK_STRESS.txt" -ItemType File
```

**What happens:**
1. Script detects file within 500ms
2. File is automatically deleted
3. Immediate cleanup and shutdown

---

### Method 3: Wait for Auto-Stop

Let the script run until the duration limit is reached.

**What happens:**
1. Script reaches time limit
2. Automatic graceful shutdown
3. All cleanup performed
4. Final statistics displayed

---

### Method 4: Kill Process (Last Resort)

⚠️ **Not recommended** - may leave test files behind

**From Task Manager:**
1. Find `powershell.exe` process
2. Right-click → End Task

**From PowerShell (as admin):**
```powershell
Get-Process powershell | Where-Object {$_.MainWindowTitle -like "*Stress*"} | Stop-Process -Force
```

**If files remain:**
```powershell
Remove-Item "C:\DiskStressTest" -Recurse -Force
```

## Monitoring Output

### Startup Information

```
========================================
Disk I/O Stress Test
========================================
I/O Type:       Mixed
Duration:       10 minutes
Test Path:      C:\DiskStressTest
File Size:      1 GB per file
Thread Count:   4
Block Size:     64 KB
Emergency Stop: C:\Scripts\STOP_DISK_STRESS.txt
========================================

Available space on drive: 245.67 GB
Required space: 4.80 GB

[14:30:15] Created test directory: C:\DiskStressTest
[14:30:15] Disk space validation passed

[14:30:16] Creating and initializing test files...
[14:30:18] Created test file 1: stresstest_1.dat (1 GB)
[14:30:20] Created test file 2: stresstest_2.dat (1 GB)
[14:30:22] Created test file 3: stresstest_3.dat (1 GB)
[14:30:24] Created test file 4: stresstest_4.dat (1 GB)

[14:30:25] Starting 4 worker threads (Mixed I/O)...
[14:30:25] Worker 1 started (Job ID: 1)
[14:30:25] Worker 2 started (Job ID: 2)
[14:30:25] Worker 3 started (Job ID: 3)
[14:30:25] Worker 4 started (Job ID: 4)

Emergency Stop Instructions:
  1. Press Ctrl+C, OR
  2. Create file: C:\Scripts\STOP_DISK_STRESS.txt

[14:30:25] Stress test running... (Will stop at 14:40:25)
```

### Real-Time Status

```
[14:30:30] IOPS: 1247 (R: 623 W: 624) | Elapsed: 0.1 min | Remaining: 9.9 min | Threads: 4
[14:30:35] IOPS: 1389 (R: 701 W: 688) | Elapsed: 0.2 min | Remaining: 9.8 min | Threads: 4
[14:30:40] IOPS: 1156 (R: 578 W: 578) | Elapsed: 0.3 min | Remaining: 9.7 min | Threads: 4
```

**Color Coding:**
- 🟢 **Green:** IOPS ≥ 100 (good performance)
- 🟡 **Yellow:** IOPS 50-99 (moderate performance)
- 🔴 **Red:** IOPS < 50 (ramping up or slow disk)

### Completion Summary

```
[14:40:25] Stopping stress test... Reason: Duration limit reached
Stopping 4 worker jobs...
Removing 4 test files...
[14:40:26] Cleanup completed

========================================
Stress Test Completed
========================================
Total Runtime: 10.02 minutes
Files Created: 4
Total Data Size: 4.00 GB
========================================
```

## I/O Patterns Explained

### Read Pattern

**What it does:**
- Opens files in read mode
- Seeks to random positions
- Reads blocks of data
- Measures read throughput and latency

**Best for testing:**
- File server read performance
- Backup restore operations
- Database read workloads
- Cache efficiency

**Typical IOPS:**
- HDD: 100-200 IOPS
- SATA SSD: 10,000-50,000 IOPS
- NVMe SSD: 100,000-500,000 IOPS

---

### Write Pattern

**What it does:**
- Opens files in write mode
- Seeks to random positions
- Writes blocks of random data
- Flushes to ensure data reaches disk

**Best for testing:**
- Database write performance
- Logging systems
- Backup operations
- Write caching effectiveness

**Typical IOPS:**
- HDD: 80-150 IOPS
- SATA SSD: 10,000-80,000 IOPS
- NVMe SSD: 50,000-300,000 IOPS

---

### Mixed Pattern

**What it does:**
- Randomly alternates between reads and writes
- 50/50 split by default
- Most realistic workload pattern

**Best for testing:**
- General disk performance
- Realistic application workloads
- Overall system capacity
- Production-like scenarios

**Typical IOPS:**
- HDD: 90-180 IOPS
- SATA SSD: 10,000-60,000 IOPS
- NVMe SSD: 80,000-400,000 IOPS

## Troubleshooting

### Issue: Insufficient Disk Space

**Error:**
```
Insufficient disk space. Required: 4.8 GB, Available: 2.3 GB
```

**Solutions:**

1. **Reduce file size:**
   ```powershell
   .\Stress-DiskIO.ps1 -FileSizeGB 0.5
   ```

2. **Reduce thread count:**
   ```powershell
   .\Stress-DiskIO.ps1 -ThreadCount 2
   ```

3. **Use different drive:**
   ```powershell
   .\Stress-DiskIO.ps1 -TestPath "D:\Test"
   ```

4. **Free up space:**
   ```powershell
   # Clean temp files
   Remove-Item $env:TEMP\* -Recurse -Force
   ```

---

### Issue: Low IOPS / Red Status

**Symptoms:**
- IOPS consistently below 50
- Red color indicators
- Much slower than expected

**Possible Causes & Solutions:**

1. **HDD with too many threads:**
   ```powershell
   # Reduce threads for spinning disks
   .\Stress-DiskIO.ps1 -ThreadCount 2
   ```

2. **Disk is busy with other operations:**
   - Check Task Manager → Performance → Disk
   - Stop unnecessary services/applications
   - Use Resource Monitor to identify processes

3. **Network storage bottleneck:**
   ```powershell
   # Test local disk instead
   .\Stress-DiskIO.ps1 -TestPath "C:\Test"
   ```

4. **Small block size on HDD:**
   ```powershell
   # Use larger blocks for spinning disks
   .\Stress-DiskIO.ps1 -BlockSizeKB 256
   ```

5. **Antivirus scanning:**
   - Add test directory to AV exclusions
   - Temporarily disable real-time scanning

**Diagnostic Commands:**
```powershell
# Check current disk activity
Get-Counter "\PhysicalDisk(*)\Current Disk Queue Length"

# Check disk latency
Get-Counter "\PhysicalDisk(*)\Avg. Disk sec/Read"
Get-Counter "\PhysicalDisk(*)\Avg. Disk sec/Write"
```

---

### Issue: Script Fails to Create Files

**Error:**
```
Failed to create test file: Access to the path is denied
```

**Solutions:**

1. **Run as administrator:**
   - Right-click PowerShell
   - Select "Run as Administrator"

2. **Check permissions:**
   ```powershell
   # Verify you can write to the path
   New-Item -Path "$TestPath\test.txt" -ItemType File
   Remove-Item "$TestPath\test.txt"
   ```

3. **Use different path:**
   ```powershell
   # Use user temp directory
   .\Stress-DiskIO.ps1 -TestPath "$env:TEMP\DiskTest"
   ```

4. **Check disk is not read-only:**
   ```powershell
   Get-Volume | Where-Object {$_.DriveLetter -eq 'C'}
   ```

---

### Issue: Files Not Cleaned Up

**Symptoms:**
- Test files remain after script exits
- Directory not removed

**Solutions:**

1. **Manual cleanup:**
   ```powershell
   Remove-Item "C:\DiskStressTest" -Recurse -Force
   ```

2. **Kill any remaining jobs:**
   ```powershell
   Get-Job | Stop-Job
   Get-Job | Remove-Job -Force
   ```

3. **Check for file locks:**
   ```powershell
   # Install Handle tool from Sysinternals
   handle.exe stresstest
   ```

4. **Force close handles:**
   - Open Resource Monitor
   - Go to CPU tab
   - Search for "stresstest"
   - End associated processes

---

### Issue: High CPU Usage

**Symptoms:**
- PowerShell using significant CPU
- System becomes sluggish

**Solutions:**

1. **This is somewhat normal** - I/O operations require CPU
2. **Reduce thread count:**
   ```powershell
   .\Stress-DiskIO.ps1 -ThreadCount 2
   ```

3. **Use larger block sizes:**
   ```powershell
   # Fewer operations = less CPU overhead
   .\Stress-DiskIO.ps1 -BlockSizeKB 256
   ```

4. **Check for other processes:**
   - Antivirus scanning test files
   - Background services interfering

---

### Issue: "Access Denied" or Permission Errors

**Error:**
```
Access to the path is denied
```

**Solutions:**

1. **Use non-system directory:**
   ```powershell
   .\Stress-DiskIO.ps1 -TestPath "D:\Test"
   ```

2. **Run as administrator:**
   - Required for C:\ root directory
   - Required for performance counters

3. **Check UAC settings:**
   - May block access to protected folders
   - Add exception or disable UAC temporarily

4. **Verify NTFS permissions:**
   ```powershell
   Get-Acl "C:\DiskStressTest" | Format-List
   ```

---

### Issue: Script Crashes or Hangs

**Symptoms:**
- PowerShell stops responding
- No output or status updates

**Solutions:**

1. **Kill and restart:**
   ```powershell
   Get-Process powershell | Stop-Process -Force
   ```

2. **Check disk health:**
   ```powershell
   # Check for disk errors
   Get-WmiObject Win32_DiskDrive | Select-Object Status
   ```

3. **Reduce load:**
   ```powershell
   # Start with minimal settings
   .\Stress-DiskIO.ps1 -ThreadCount 1 -DurationMinutes 2
   ```

4. **Check event logs:**
   ```powershell
   Get-EventLog -LogName System -Newest 50 | Where-Object {$_.Source -like "*disk*"}
   ```

## Best Practices

### ✅ Do's

1. **Test Non-System Drives First**
   - Test D:, E:, etc. before C:
   - Avoid filling system drive
   - Keep system responsive

2. **Monitor While Running**
   - Open Performance Monitor (perfmon)
   - Watch Resource Monitor
   - Check Task Manager → Performance

3. **Use Appropriate Settings**
   - Match block size to your use case
   - Start with low thread count
   - Increase gradually

4. **Verify Disk Health First**
   ```powershell
   Get-PhysicalDisk | Get-StorageReliabilityCounter
   ```

5. **Baseline Before Changes**
   - Test before infrastructure changes
   - Compare results over time
   - Document all test parameters

6. **Clean Up Manually if Needed**
   - Verify files are deleted
   - Check disk space after test

### ❌ Don'ts

1. **Don't Fill System Drive**
   - Never use C:\ on servers
   - Always leave 20% free space
   - Watch space during test

2. **Don't Run Indefinitely**
   - Set reasonable duration limits
   - Don't exceed 2 hours typically
   - Use monitoring tools for longer tests

3. **Don't Test Production Drives During Peak**
   - Schedule during maintenance windows
   - Coordinate with operations team
   - Document test windows

4. **Don't Ignore Warnings**
   - Space warnings are serious
   - Performance counters errors matter
   - Stop if disk shows errors

5. **Don't Use Too Many Threads on HDD**
   - HDDs perform poorly with >4 threads
   - Causes disk thrashing
   - Reduces overall performance

6. **Don't Skip Space Check**
   - Only skip if absolutely necessary
   - Could fill disk and crash system
   - Especially dangerous on C:\

### 📋 Pre-Test Checklist

- [ ] Disk has sufficient free space (+20% buffer)
- [ ] Not running on system drive (or have approval)
- [ ] Monitoring tools ready (perfmon, Resource Monitor)
- [ ] Team notified if testing production
- [ ] Duration is appropriate (typically 5-20 min)
- [ ] Thread count appropriate for disk type
- [ ] Know how to stop (Ctrl+C)
- [ ] Not during peak business hours (if production)

### 📊 Post-Test Checklist

- [ ] Script fully stopped and cleaned up
- [ ] All test files deleted
- [ ] Test directory removed
- [ ] Disk space recovered
- [ ] Performance data collected
- [ ] Results documented
- [ ] Any anomalies investigated
- [ ] Disk health checked

## Performance Tuning

### Optimizing for Different Scenarios

#### High IOPS Testing (Random I/O)
```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -BlockSizeKB 4 `
    -ThreadCount 8 `
    -FileSizeGB 1 `
    -DurationMinutes 10
```
**Goal:** Maximum IOPS, small random operations

#### High Throughput Testing (Sequential I/O)
```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -BlockSizeKB 1024 `
    -ThreadCount 2 `
    -FileSizeGB 5 `
    -DurationMinutes 15
```
**Goal:** Maximum MB/s, large sequential operations

#### Database Simulation (OLTP)
```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Mixed `
    -BlockSizeKB 8 `
    -ThreadCount 12 `
    -FileSizeGB 2 `
    -DurationMinutes 20
```
**Goal:** Simulate SQL Server transactional workload

#### Backup/Restore Simulation
```powershell
.\Stress-DiskIO.ps1 `
    -TargetIOType Write `
    -BlockSizeKB 256 `
    -ThreadCount 4 `
    -FileSizeGB 10 `
    -DurationMinutes 30
```
**Goal:** Sustained write throughput

### Disk Type Recommendations

#### HDD (Spinning Disks)
```powershell
# Conservative settings for HDDs
.\Stress-DiskIO.ps1 `
    -ThreadCount 2 `
    -BlockSizeKB 256 `
    -FileSizeGB 2
```
**Characteristics:**
- Low thread count (2-4)
- Larger block sizes (128KB-1MB)
- Lower IOPS (100-200)
- Higher latency

#### SATA SSD
```powershell
# Moderate settings for SATA SSDs
.\Stress-DiskIO.ps1 `
    -ThreadCount 8 `
    -BlockSizeKB 64 `
    -FileSizeGB 5
```
**Characteristics:**
- Medium thread count (4-8)
- Medium block sizes (64KB-256KB)
- High IOPS (10,000-50,000)
- Low latency

#### NVMe SSD
```powershell
# Aggressive settings for NVMe
.\Stress-DiskIO.ps1 `
    -ThreadCount 16 `
    -BlockSizeKB 64 `
    -FileSizeGB 10
```
**Characteristics:**
- High thread count (8-16)
- Any block size works well
- Very high IOPS (100,000+)
- Very low latency

### Understanding IOPS

**IOPS (I/O Operations Per Second)** - Number of read/write operations completed per second.

**Factors Affecting IOPS:**
1. **Disk Type** - SSDs vastly outperform HDDs
2. **Block Size** - Smaller blocks = higher IOPS potential
3. **Thread Count** - More threads can increase IOPS (up to a point)
4. **Access Pattern** - Sequential vs random
5. **Queue Depth** - How many I/O requests are pending

**Typical IOPS by Disk Type:**
| Disk Type | Random Read | Random Write | Sequential Read | Sequential Write |
|-----------|-------------|--------------|-----------------|------------------|
| 7200 RPM HDD | 75-100 | 75-100 | 100-200 | 100-200 |
| 10K RPM HDD | 125-150 | 125-150 | 150-200 | 150-200 |
| SATA SSD | 10,000-50,000 | 10,000-80,000 | 50,000+ | 50,000+ |
| NVMe SSD | 100,000-500,000 | 50,000-300,000 | 500,000+ | 300,000+ |

### Block Size Impact

| Block Size | IOPS Potential | Throughput | Use Case |
|------------|----------------|------------|----------|
| 4KB | Very High | Low | Database OLTP |
| 8KB | High | Low | SQL Server |
| 64KB | Medium | Medium | General purpose |
| 256KB | Low | High | Data warehouse |
| 1MB | Very Low | Very High | Video streaming |

**Formula:**
```
Throughput (MB/s) = IOPS × Block Size (KB) / 1024
```

**Example:**
- 1,000 IOPS × 64KB = 62.5 MB/s
- 10,000 IOPS × 4KB = 39 MB/s

## Advanced Usage

### Integration with Monitoring Systems

**Example: Automated alert testing**
```powershell
# Start stress test in background
$job = Start-Job -ScriptBlock {
    & "C:\Scripts\Stress-DiskIO.ps1" `
        -TargetIOType Write `
        -ThreadCount 8 `
        -DurationMinutes 20
}

# Wait for monitoring alert to trigger
Start-Sleep -Seconds 300

# Check if alert was received
$alertReceived = Test-MonitoringAlert -Type "DISK_IO_HIGH"

if ($alertReceived) {
    Write-Host "Alert test PASSED" -ForegroundColor Green
} else {
    Write-Host "Alert test FAILED" -ForegroundColor Red
}

# Stop test
New-Item -Path "C:\Scripts\STOP_DISK_STRESS.txt" -ItemType File
Wait-Job $job
Receive-Job $job
```

### Scheduled Testing

**Example: Weekly disk health check**
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\Stress-DiskIO.ps1 -TargetIOType Mixed -DurationMinutes 15"

$trigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Sunday `
    -At 2AM

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false

Register-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -TaskName "Weekly_Disk_IO_Test" `
    -Description "Weekly disk I/O health check"
```

### Performance Baseline Collection

**Example: Collect and compare baselines**
```powershell
# Baseline test function
function Get-DiskIOBaseline {
    param([string]$TestName)
    
    Write-Host "Starting baseline test: $TestName" -ForegroundColor Cyan
    
    # Start transcript for logging
    Start-Transcript -Path "C:\Logs\DiskIO_$TestName_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    # Run test
    .\Stress-DiskIO.ps1 `
        -TargetIOType Mixed `
        -ThreadCount 4 `
        -DurationMinutes 10
    
    Stop-Transcript
    
    # Collect performance data
    $perfData = Get-Counter `
        "\PhysicalDisk(*)\Disk Reads/sec", `
        "\PhysicalDisk(*)\Disk Writes/sec", `
        "\PhysicalDisk(*)\Avg. Disk sec/Read", `
        "\PhysicalDisk(*)\Avg. Disk sec/Write"
    
    return $perfData
}

# Collect baseline
$baseline = Get-DiskIOBaseline -TestName "Pre_Upgrade"

# After changes, compare
$newBaseline = Get-DiskIOBaseline -TestName "Post_Upgrade"

# Compare results
Compare-Object $baseline $newBaseline
```

### Logging and Reporting

**Example: Comprehensive test report**
```powershell
# Create test report
$reportPath = "C:\Reports\DiskIO_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$testParams = @{
    TargetIOType = "Mixed"
    ThreadCount = 8
    DurationMinutes = 15
    FileSizeGB = 2
}

# Start transcript
Start-Transcript -Path "C:\Logs\DiskIO_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Get pre-test disk info
$preDiskInfo = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, OperationalStatus, HealthStatus

# Run test
.\Stress-DiskIO.ps1 @testParams

# Get post-test disk info
$postDiskInfo = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, OperationalStatus, HealthStatus

Stop-Transcript

# Generate HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Disk I/O Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .header { background-color: #f2f2f2; padding: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Disk I/O Stress Test Report</h1>
        <p>Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <h2>Test Parameters</h2>
    <table>
        <tr><th>Parameter</th><th>Value</th></tr>
        <tr><td>I/O Type</td><td>$($testParams.TargetIOType)</td></tr>
        <tr><td>Thread Count</td><td>$($testParams.ThreadCount)</td></tr>
        <tr><td>Duration</td><td>$($testParams.DurationMinutes) minutes</td></tr>
        <tr><td>File Size</td><td>$($testParams.FileSizeGB) GB</td></tr>
    </table>
    
    <h2>Disk Health Status</h2>
    <table>
        <tr><th>Disk</th><th>Status</th><th>Health</th></tr>
        $(foreach ($disk in $postDiskInfo) {
            "<tr><td>$($disk.FriendlyName)</td><td>$($disk.OperationalStatus)</td><td>$($disk.HealthStatus)</td></tr>"
        })
    </table>
</body>
</html>
"@

$html | Out-File $reportPath
Write-Host "Report saved: $reportPath" -ForegroundColor Green
```

## FAQ

**Q: Will this harm my hard drive or SSD?**  
A: No. The script performs normal I/O operations that disks are designed to handle. Modern SSDs have wear leveling and can handle millions of write cycles. However, avoid running continuously for days.

**Q: Can I run this on my system drive (C:\)?**  
A: Yes, but use caution. Ensure you have sufficient free space and won't fill the drive. Better to test on a non-system drive.

**Q: How accurate are the IOPS measurements?**  
A: Reasonably accurate for comparing relative performance. For precise benchmarking, use tools like CrystalDiskMark or ATTO Disk Benchmark.

**Q: Why do I see lower IOPS than advertised?**  
A: Advertised IOPS are typically best-case scenarios with optimal queue depth and workload. Real-world performance varies based on many factors.

**Q: Can I test network drives?**  
A: Yes, but you'll be testing network performance, not just disk performance. Network latency and bandwidth become the primary bottlenecks.

**Q: Will this work on Windows Server?**  
A: Yes, fully compatible with Windows Server 2012 R2 and later.

**Q: Can I run multiple instances simultaneously?**  
A: Not recommended. Multiple instances make it difficult to interpret results and can cause unpredictable behavior.

**Q: Does this test NVMe performance accurately?**  
A: For basic testing, yes. For detailed NVMe benchmarking, use specialized tools that can leverage NVMe-specific features and higher queue depths.

**Q: How long should I run the test?**  
A: 5-15 minutes is typically sufficient for most testing scenarios. Longer tests (30-60 minutes) are useful for endurance and thermal testing.

**Q: What's a good IOPS number?**  
A: Depends on your disk type. See the "Understanding IOPS" section for typical ranges by disk type.

**Q: Can I use this to test RAID arrays?**  
A: Yes, it will test the overall performance of the RAID array. Results will depend on RAID level and configuration.

**Q: Why does performance decrease over time?**  
A: Could be thermal throttling (especially SSDs), disk cache filling, or other system processes competing for resources.

## Support & Contributing

### Getting Help

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review error messages carefully
3. Test with default parameters first
4. Verify disk health before testing

### Reporting Issues

When reporting problems, include:
- PowerShell version (`$PSVersionTable`)
- Windows version (`Get-ComputerSystem`)
- Disk type (HDD, SSD, NVMe)
- Exact command used
- Complete error message
- Disk space available
- Screenshots if relevant

### Performance Metrics to Collect

When testing, gather these metrics:
```powershell
# Before test
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, Size, HealthStatus

# During test (from another window)
Get-Counter "\PhysicalDisk(*)\*" -Continuous

# After test
Get-PhysicalDisk | Get-StorageReliabilityCounter
```

## Related Tools

For comprehensive disk testing, consider these tools:

**Benchmarking Tools:**
- **CrystalDiskMark** - Popular disk benchmark tool
- **ATTO Disk Benchmark** - Industry standard
- **AS SSD Benchmark** - SSD-specific testing
- **Iometer** - Advanced I/O load generator

**Monitoring Tools:**
- **Performance Monitor (perfmon)** - Built-in Windows tool
- **Resource Monitor** - Real-time resource usage
- **DiskSpd** - Microsoft's disk testing tool
- **Task Manager** - Basic monitoring

**Health Monitoring:**
- **CrystalDiskInfo** - Disk health monitoring
- **HD Tune** - HDD health and benchmarking
- **Samsung Magician** - Samsung SSD management
- **Intel SSD Toolbox** - Intel SSD management

## Additional Resources

- [Microsoft DiskSpd Documentation](https://github.com/Microsoft/diskspd)
- [Understanding IOPS and Throughput](https://docs.microsoft.com/en-us/azure/virtual-machines/premium-storage-performance)
- [SSD Endurance and Lifespan](https://www.anandtech.com/show/6489/playing-with-op)
- [Windows Performance Monitor](https://docs.microsoft.com/en-us/windows-server/administration/performance-tuning/)

## License & Disclaimer

**Disclaimer:** This script is provided as-is for testing purposes. Always test in non-production environments first. The authors are not responsible for any issues arising from use of this script, including data loss or disk wear.

**License:** Free to use, modify, and distribute. Attribution appreciated but not required.

## Version History

**Version 1.0** (October 2025)
- Initial release
- Support for Read, Write, and Mixed I/O patterns
- Configurable threads, file sizes, and block sizes
- Multiple safety mechanisms
- Automatic cleanup
- Real-time IOPS monitoring

---

**Version:** 1.0  
**Last Updated:** October 2025  
**Compatibility:** Windows PowerShell 5.1+, PowerShell Core 7+  
**Tested On:** Windows 10, Windows 11, Windows Server 2016-2022