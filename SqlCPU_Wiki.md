# SQL Server CPU Stress Test Script

A safe and controlled PowerShell script for testing SQL Server CPU utilization with built-in failsafe mechanisms. Perfect for testing monitoring systems, auto-scaling, alerts, and performance baselines.

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
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This script increases SQL Server CPU utilization to a specified target percentage by running CPU-intensive queries in parallel. It's designed for:

- Testing monitoring and alerting systems
- Validating auto-scaling configurations
- Performance baseline testing
- Stress testing SQL Server infrastructure
- Training and demonstrations

**Key Point:** This is a **read-only** stress test. It does not modify any data, create tables, or make any permanent changes to your database.

## Safety Features

### 🛡️ Multiple Failsafes

1. **Hard CPU Limit** - Maximum target capped at 95% to prevent system lockup
2. **Time-Based Auto-Stop** - Automatically stops after specified duration
3. **Emergency Stop File** - Instant stop by creating a trigger file
4. **Ctrl+C Handler** - Graceful shutdown with cleanup
5. **Automatic Cleanup** - Closes all connections and stops workers on exit
6. **Connection Validation** - Tests connectivity before starting
7. **Uses TempDB** - Default database is tempdb (non-production)
8. **Read-Only Operations** - Only runs SELECT queries with calculations

### 🔒 What It Doesn't Do

- ❌ Does NOT modify any data
- ❌ Does NOT create/drop tables
- ❌ Does NOT use excessive memory
- ❌ Does NOT lock tables
- ❌ Does NOT run indefinitely
- ❌ Does NOT impact disk I/O significantly

## Prerequisites

### Required
- Windows PowerShell 5.1 or later (or PowerShell Core 7+)
- SQL Server (any version from 2012+)
- Windows Authentication or SQL Authentication access to SQL Server
- Permissions to connect to the target database (default: tempdb)

### Optional
- SQL Server Management Studio (for monitoring)
- Performance Monitor (perfmon) for detailed metrics

### Permissions Required
- `CONNECT` permission to the target database
- `VIEW SERVER STATE` permission (for CPU monitoring)
- Member of `db_datareader` role (minimal access)

## Quick Start

### 1. Download the Script

Save the script as `Stress-SqlCpu.ps1` in a directory of your choice.

### 2. Run with Default Settings

```powershell
# Basic run: 70% CPU for 5 minutes on localhost
.\Stress-SqlCpu.ps1
```

### 3. Run with Custom Target

```powershell
# 90% CPU for 10 minutes
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 10
```

### 4. Stop Anytime

Press **Ctrl+C** to stop immediately with automatic cleanup.

## Parameters

### `-TargetCpuPercent`
**Type:** Integer  
**Range:** 1-95  
**Default:** 70  
**Required:** No

The target CPU utilization percentage for SQL Server.

**Examples:**
```powershell
# Light load - 50%
.\Stress-SqlCpu.ps1 -TargetCpuPercent 50

# Heavy load - 90%
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90

# Maximum allowed - 95%
.\Stress-SqlCpu.ps1 -TargetCpuPercent 95
```

**Notes:**
- The script will attempt to reach this target but may vary ±5-10%
- Capped at 95% for safety (script will reject values above 95)
- Actual CPU usage depends on server resources and workload

---

### `-DurationMinutes`
**Type:** Integer  
**Range:** 1-60  
**Default:** 5  
**Required:** No

Maximum duration to run the stress test in minutes.

**Examples:**
```powershell
# Quick test - 2 minutes
.\Stress-SqlCpu.ps1 -DurationMinutes 2

# Medium test - 15 minutes
.\Stress-SqlCpu.ps1 -DurationMinutes 15

# Long test - 30 minutes
.\Stress-SqlCpu.ps1 -DurationMinutes 30
```

**Notes:**
- Script will automatically stop after this duration
- Maximum allowed is 60 minutes (1 hour)
- You can always stop earlier with Ctrl+C

---

### `-SqlInstance`
**Type:** String  
**Default:** "localhost"  
**Required:** No

The SQL Server instance name to connect to.

**Examples:**
```powershell
# Local default instance
.\Stress-SqlCpu.ps1 -SqlInstance "localhost"

# Local named instance
.\Stress-SqlCpu.ps1 -SqlInstance "localhost\SQLEXPRESS"

# Remote server
.\Stress-SqlCpu.ps1 -SqlInstance "SQLSERVER01"

# Remote named instance
.\Stress-SqlCpu.ps1 -SqlInstance "SQLSERVER01\PRODUCTION"

# Fully qualified domain name
.\Stress-SqlCpu.ps1 -SqlInstance "sqlserver.domain.com"

# IP address
.\Stress-SqlCpu.ps1 -SqlInstance "192.168.1.100"

# IP with named instance
.\Stress-SqlCpu.ps1 -SqlInstance "192.168.1.100\SQLEXPRESS"
```

**Notes:**
- Uses Windows Authentication by default
- For remote servers, ensure firewall allows SQL Server port (default 1433)
- Named instances use dynamic ports unless configured otherwise

---

### `-Database`
**Type:** String  
**Default:** "tempdb"  
**Required:** No

The database to use for running stress queries.

**Examples:**
```powershell
# Use default tempdb (recommended)
.\Stress-SqlCpu.ps1 -Database "tempdb"

# Use test database
.\Stress-SqlCpu.ps1 -Database "TestDB"

# Use master (not recommended for production)
.\Stress-SqlCpu.ps1 -Database "master"
```

**Notes:**
- **Recommended:** Use `tempdb` for stress testing
- Queries are read-only and don't modify data
- Ensure you have CONNECT permission to the database
- Avoid using production databases if possible

---

### `-EmergencyStopFile`
**Type:** String  
**Default:** "$PSScriptRoot\STOP_SQL_STRESS.txt"  
**Required:** No

Path to the emergency stop trigger file.

**Examples:**
```powershell
# Default location (same folder as script)
.\Stress-SqlCpu.ps1

# Custom location
.\Stress-SqlCpu.ps1 -EmergencyStopFile "C:\Temp\STOP.txt"

# Network share
.\Stress-SqlCpu.ps1 -EmergencyStopFile "\\SERVER\Share\STOP.txt"
```

**How it works:**
- Script checks for this file every 500 milliseconds
- If the file exists, script stops immediately
- File is automatically deleted when script stops
- Useful for automation or remote stop triggers

**To trigger emergency stop:**
```powershell
# Create the file to stop the script
New-Item -Path "STOP_SQL_STRESS.txt" -ItemType File
```

## Usage Examples

### Example 1: Basic Monitoring Test
Test if your monitoring system detects high CPU:

```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 85 -DurationMinutes 3
```

### Example 2: Auto-Scaling Validation
Trigger auto-scaling rules:

```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 15 -SqlInstance "PRODSERVER\SQL2019"
```

### Example 3: Alert Testing
Test alert thresholds at different levels:

```powershell
# Warning level - 70%
.\Stress-SqlCpu.ps1 -TargetCpuPercent 70 -DurationMinutes 5

# Critical level - 90%
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 5
```

### Example 4: Remote Server Testing
Test a remote SQL Server:

```powershell
.\Stress-SqlCpu.ps1 `
    -TargetCpuPercent 80 `
    -DurationMinutes 10 `
    -SqlInstance "192.168.1.50\SQLEXPRESS" `
    -Database "tempdb"
```

### Example 5: Automated Testing with Stop File
Use in automation scripts:

```powershell
# Start stress test in background
Start-Job -ScriptBlock {
    & "C:\Scripts\Stress-SqlCpu.ps1" -TargetCpuPercent 85 -DurationMinutes 30
}

# Later... stop it remotely
New-Item -Path "C:\Scripts\STOP_SQL_STRESS.txt" -ItemType File
```

### Example 6: Progressive Load Testing
Gradually increase load:

```powershell
# Step 1: Light load
.\Stress-SqlCpu.ps1 -TargetCpuPercent 50 -DurationMinutes 5

# Step 2: Medium load
.\Stress-SqlCpu.ps1 -TargetCpuPercent 70 -DurationMinutes 5

# Step 3: Heavy load
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 5
```

## How It Works

### Architecture

```
PowerShell Script
    ↓
Creates N Worker Jobs (parallel threads)
    ↓
Each Worker → SQL Connection → CPU-Intensive Query
    ↓
Monitors SQL CPU every 10 seconds
    ↓
Auto-stops after duration OR emergency trigger
    ↓
Automatic cleanup (close connections, stop jobs)
```

### Worker Calculation

The script calculates the number of worker threads based on:
- Number of logical CPU cores on the server
- Target CPU percentage

**Formula:**
```
Workers = Floor(LogicalCores × (TargetCPU / 100))
Minimum: 1 worker
```

**Example:**
- Server with 8 cores
- Target: 80% CPU
- Workers: Floor(8 × 0.8) = 6 workers

### CPU-Intensive Operations

Each worker runs queries that perform:

1. **Prime Number Calculations**
   - Checks if numbers are prime using division
   - CPU-bound mathematical operations

2. **Hash Calculations**
   - SHA2-256 hash generation
   - Cryptographic operations (CPU-intensive)

3. **Iterative Loops**
   - Controlled loops with calculations
   - Prevents query timeout with small delays

**Sample Query Pattern:**
```sql
-- Runs for ~30 seconds, then repeats
WHILE GETDATE() < @EndTime
BEGIN
    -- Prime number check
    -- SHA-256 hash calculation
    -- Counter increments
END
```

### CPU Monitoring

The script queries SQL Server's internal ring buffers to get accurate CPU usage:

```sql
-- Retrieves last 30 samples of SQL CPU utilization
-- Each sample represents ~1 second
-- Averages them for current CPU percentage
```

**Metrics Displayed:**
- **SQL CPU:** Current SQL Server CPU usage
- **Target:** Your specified target
- **Elapsed:** Time since start
- **Remaining:** Time until auto-stop

## Emergency Stop Procedures

### Method 1: Ctrl+C (Recommended)

Simply press `Ctrl+C` in the PowerShell window running the script.

**What happens:**
1. Graceful shutdown initiated
2. All worker jobs stopped
3. SQL connections closed
4. Resources cleaned up
5. Final status displayed

### Method 2: Emergency Stop File

Create the emergency stop file to trigger immediate shutdown.

**From the same machine:**
```powershell
New-Item -Path "STOP_SQL_STRESS.txt" -ItemType File
```

**From a remote machine:**
```powershell
New-Item -Path "\\SERVER\C$\Scripts\STOP_SQL_STRESS.txt" -ItemType File
```

**From Command Prompt:**
```cmd
echo. > STOP_SQL_STRESS.txt
```

**What happens:**
1. Script detects file within 500ms
2. File is automatically deleted
3. Immediate cleanup and shutdown

### Method 3: Kill PowerShell Process (Last Resort)

⚠️ **Not recommended** - may leave orphaned SQL connections

**From Task Manager:**
1. Find `powershell.exe` process
2. Right-click → End Task

**From PowerShell (as admin):**
```powershell
Get-Process powershell | Where-Object {$_.MainWindowTitle -like "*Stress*"} | Stop-Process -Force
```

**Note:** This method may not clean up properly. Use Ctrl+C or stop file instead.

## Monitoring Output

### Status Display

The script displays real-time status every 10 seconds:

```
[14:30:25] SQL CPU: 87.5% | Target: 90% | Elapsed: 0.2 min | Remaining: 9.8 min
```

**Color Coding:**
- 🟢 **Green:** CPU within 5% of target (optimal)
- 🟡 **Yellow:** CPU within 15% of target (acceptable)
- 🔴 **Red:** CPU more than 15% below target (ramping up)

### Startup Information

```
========================================
SQL Server CPU Stress Test
========================================
Target CPU:     90%
Duration:       10 minutes
SQL Instance:   localhost
Database:       tempdb
Emergency Stop: C:\Scripts\STOP_SQL_STRESS.txt
========================================

[14:30:15] Validating SQL Server connection...
[14:30:15] Connection successful

[14:30:16] Starting 7 worker threads...
[14:30:16] Worker 1 started (Job ID: 1)
[14:30:16] Worker 2 started (Job ID: 2)
...

Emergency Stop Instructions:
  1. Press Ctrl+C, OR
  2. Create file: C:\Scripts\STOP_SQL_STRESS.txt
```

### Completion Summary

```
[14:40:25] Stopping stress test... Reason: Duration limit reached
Stopping 7 worker jobs...
Closing SQL connections...
[14:40:26] Cleanup completed

========================================
Stress Test Completed
========================================
Total Runtime: 10.02 minutes
========================================
```

## Troubleshooting

### Issue: "Cannot connect to SQL Server"

**Error:**
```
Cannot connect to SQL Server 'localhost': Login failed for user 'DOMAIN\User'
```

**Solutions:**
1. Verify SQL Server is running:
   ```powershell
   Get-Service MSSQLSERVER  # Default instance
   Get-Service MSSQL$SQLEXPRESS  # Named instance
   ```

2. Check SQL Server authentication mode (Windows Auth vs SQL Auth)

3. Verify firewall allows SQL Server port:
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 1433
   ```

4. For remote servers, use SQL Server Configuration Manager to enable TCP/IP

---

### Issue: CPU Not Reaching Target

**Symptoms:**
- CPU stays significantly below target (>20% difference)
- Red status indicators

**Possible Causes & Solutions:**

1. **Server has many cores:**
   - Script may need more workers
   - Try a higher target percentage

2. **Other processes using CPU:**
   - Check Task Manager for other high-CPU processes
   - Consider stopping non-essential services temporarily

3. **SQL Server throttling:**
   - Check max degree of parallelism (MAXDOP) settings
   - Verify Resource Governor isn't limiting CPU

4. **Performance bottleneck:**
   - Check if SQL Server is waiting on disk I/O
   - Monitor wait statistics

**Diagnostic Query:**
```sql
-- Check current SQL Server settings
SELECT 
    @@SERVERNAME AS ServerName,
    cpu_count AS LogicalCPUs,
    scheduler_count AS Schedulers
FROM sys.dm_os_sys_info;
```

---

### Issue: Script Exits Immediately

**Symptoms:**
- Script starts but stops within seconds
- No workers created

**Solutions:**

1. **Check execution policy:**
   ```powershell
   Get-ExecutionPolicy
   # If Restricted, change it:
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Verify SQL connection:**
   ```powershell
   # Test manually
   sqlcmd -S localhost -Q "SELECT @@VERSION"
   ```

3. **Check for errors:**
   - Run script with `-Verbose` flag
   - Review any error messages

---

### Issue: "Access Denied" or Permission Errors

**Error:**
```
The user does not have permission to perform this action
```

**Solutions:**

1. **Grant VIEW SERVER STATE:**
   ```sql
   USE master;
   GRANT VIEW SERVER STATE TO [DOMAIN\User];
   ```

2. **Ensure database access:**
   ```sql
   USE tempdb;
   CREATE USER [DOMAIN\User] FOR LOGIN [DOMAIN\User];
   GRANT CONNECT TO [DOMAIN\User];
   ```

3. **Run as administrator:**
   - Right-click PowerShell
   - Select "Run as Administrator"

---

### Issue: Workers Stay Running After Stop

**Symptoms:**
- Script exits but SQL queries continue
- Connections remain open

**Solutions:**

1. **Kill background jobs:**
   ```powershell
   Get-Job | Stop-Job
   Get-Job | Remove-Job -Force
   ```

2. **Kill SQL connections:**
   ```sql
   -- Find sessions running stress queries
   SELECT session_id, login_name, program_name, status
   FROM sys.dm_exec_sessions
   WHERE program_name LIKE '%PowerShell%';
   
   -- Kill specific session
   KILL <session_id>;
   ```

3. **Restart SQL Server (last resort):**
   ```powershell
   Restart-Service MSSQLSERVER
   ```

---

### Issue: High Memory Usage

**Symptoms:**
- PowerShell process uses excessive memory
- System becomes slow

**Solutions:**

1. **This is normal** - Multiple workers create memory overhead
2. **Reduce duration** - Shorter tests use less memory
3. **Reduce target CPU** - Fewer workers = less memory
4. **Restart PowerShell** after test completes

---

## Best Practices

### ✅ Do's

1. **Test in Non-Production First**
   - Always test in dev/test environments first
   - Validate the script behavior before production use

2. **Monitor While Running**
   - Open SQL Server Management Studio
   - Watch Activity Monitor during the test
   - Use Performance Monitor for detailed metrics

3. **Use Reasonable Durations**
   - Start with 5-10 minutes
   - Extend only if needed for your test case

4. **Set Appropriate Targets**
   - 70-85% for general testing
   - 90%+ only for stress testing
   - Never use 95% in production

5. **Schedule During Maintenance Windows**
   - For production servers, use maintenance windows
   - Coordinate with your DBA team

6. **Document Your Testing**
   - Record parameters used
   - Note any anomalies observed
   - Track results for future reference

### ❌ Don'ts

1. **Don't Run on Production Without Approval**
   - Always get DBA approval first
   - Document the test plan
   - Have rollback procedures ready

2. **Don't Run Indefinitely**
   - Always set a duration limit
   - Don't exceed 30-60 minutes typically

3. **Don't Ignore Warnings**
   - If the script shows errors, investigate
   - Don't force it to continue if SQL is unhealthy

4. **Don't Run Multiple Instances**
   - One stress test at a time
   - Multiple instances can cause unpredictable behavior

5. **Don't Forget to Monitor**
   - Always watch the test while it runs
   - Be ready to stop if issues arise

6. **Don't Test During Peak Hours**
   - Avoid business hours for production testing
   - Schedule during low-usage periods

### 📋 Pre-Test Checklist

- [ ] Approval obtained (if production)
- [ ] Backup of test database (if not using tempdb)
- [ ] Monitoring tools open (SSMS, perfmon)
- [ ] Team notified of test window
- [ ] Emergency stop procedure understood
- [ ] Test duration appropriate for goals
- [ ] Rollback plan documented

### 📊 Post-Test Checklist

- [ ] Script fully stopped and cleaned up
- [ ] SQL connections all closed
- [ ] Monitoring data collected
- [ ] Results documented
- [ ] Any anomalies investigated
- [ ] Team notified of completion
- [ ] Lessons learned recorded

## Advanced Usage

### Integration with Monitoring Systems

**Example: Trigger alert and validate response**
```powershell
# Start stress test
$job = Start-Job -ScriptBlock {
    & "C:\Scripts\Stress-SqlCpu.ps1" -TargetCpuPercent 90 -DurationMinutes 15
}

# Wait for alert to trigger (check your monitoring system)
Start-Sleep -Seconds 300

# Validate alert received
$alertReceived = Test-AlertSystem -AlertType "SQL_HIGH_CPU"

# Stop test
New-Item -Path "C:\Scripts\STOP_SQL_STRESS.txt" -ItemType File

# Wait for cleanup
Wait-Job $job
Receive-Job $job
```

### Scheduled Testing

**Example: Weekly automated test**
```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\Stress-SqlCpu.ps1 -TargetCpuPercent 80 -DurationMinutes 10"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2AM

Register-ScheduledTask -Action $action -Trigger $trigger `
    -TaskName "SQL_Weekly_Load_Test" -Description "Weekly SQL CPU load test"
```

### Logging Results

**Example: Log to file**
```powershell
# Run with transcript
Start-Transcript -Path "C:\Logs\SqlStress_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
.\Stress-SqlCpu.ps1 -TargetCpuPercent 85 -DurationMinutes 10
Stop-Transcript
```

## FAQ

**Q: Will this harm my SQL Server?**  
A: No. The script only runs read-only queries and includes multiple safety mechanisms. However, high CPU usage may temporarily slow other queries.

**Q: Can I run this on production?**  
A: Yes, but only with proper approval, monitoring, and during appropriate time windows. Test in non-production first.

**Q: How accurate is the CPU target?**  
A: Typically within ±5-10% of target. Exact results depend on server resources and current workload.

**Q: What if I set target to 100%?**  
A: The script caps at 95% maximum for safety. You cannot set higher than 95%.

**Q: Will this affect other databases?**  
A: Minimal impact. The script uses CPU resources but doesn't lock tables or consume excessive memory. Other databases may experience slight performance degradation.

**Q: Can I run multiple scripts simultaneously?**  
A: Not recommended. Multiple instances can cause unpredictable CPU behavior and make it difficult to control.

**Q: Does this work with SQL Server on Linux?**  
A: The PowerShell script runs on Windows, but can connect to SQL Server on Linux via the network.

**Q: What SQL Server versions are supported?**  
A: SQL Server 2012 and later. The script uses standard T-SQL that works across all modern versions.

## Support & Contributing

### Getting Help

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review error messages carefully
3. Test with default parameters first
4. Verify SQL Server connectivity manually

### Reporting Issues

When reporting problems, include:
- PowerShell version (`$PSVersionTable`)
- SQL Server version (`SELECT @@VERSION`)
- Exact command used
- Complete error message
- Screenshots if relevant

## License & Disclaimer

**Disclaimer:** This script is provided as-is for testing purposes. Always test in non-production environments first. The authors are not responsible for any issues arising from use of this script.

**License:** Free to use, modify, and distribute. Attribution appreciated but not required.

---

**Version:** 1.0  
**Last Updated:** October 2025  
**Author:** nocticdr