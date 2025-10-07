# SQL Server Load Testing Tools

Quick reference for testing SQL Server performance with CPU and Disk I/O load generators.

## 🚀 Quick Start

### CPU Load Testing
```powershell
# Basic CPU test: 70% for 5 minutes
.\Invoke-SqlServerCpuStress.ps1

# High load test: 90% for 10 minutes
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 90 -DurationMinutes 10
```

### Disk I/O Load Testing
```powershell
# Basic disk test: Mixed I/O, 1GB files, 4 threads, 5 minutes
.\Invoke-SqlServerDiskStress.ps1

# Heavy write test: 8 threads, 2GB files, 10 minutes
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Write -FileSizeGB 2 -ThreadCount 8 -DurationMinutes 10
```

## 🛠️ Tool Overview

| Tool | Purpose | Default Settings | Safety Features |
|------|---------|------------------|-----------------|
| **SQL CPU Load Generator** | Test CPU utilization, monitoring alerts, auto-scaling | 70% CPU, 5 min, localhost | 95% cap, auto-stop, read-only |
| **SQL Disk I/O Load Generator** | Test disk performance, storage alerts, backup performance | Mixed I/O, 1GB files, 4 threads, 5 min | Space validation, auto-cleanup, isolated testing |

## 📋 Common Use Cases

### Monitoring & Alerting
```powershell
# Test CPU monitoring (70% threshold)
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 75 -DurationMinutes 5

# Test disk I/O monitoring
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Write -ThreadCount 8 -DurationMinutes 10
```

### Auto-Scaling Validation
```powershell
# Trigger CPU auto-scaling
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 85 -DurationMinutes 20

# Test storage scaling
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Mixed -ThreadCount 16 -DurationMinutes 15
```

### Performance Baselines
```powershell
# CPU baseline
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 60 -DurationMinutes 10

# Disk baseline
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Mixed -BlockSizeKB 64 -DurationMinutes 15
```

## ⚙️ Quick Parameter Reference

### CPU Load Generator Parameters

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `-TargetCpuPercent` | Integer | 70 | 1-95 | Target CPU percentage |
| `-DurationMinutes` | Integer | 5 | 1-60 | How long to run (auto-stops) |
| `-SqlInstance` | String | localhost | - | SQL Server instance name |
| `-Database` | String | tempdb | - | Database to use (tempdb recommended) |
| `-EmergencyStopFile` | String | STOP_SQL_STRESS.txt | - | Create this file to stop instantly |

### Disk I/O Load Generator Parameters

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `-TargetIOType` | String | Mixed | Read/Write/Mixed | Type of I/O operations |
| `-DurationMinutes` | Integer | 5 | 1-120 | How long to run (auto-stops) |
| `-TestPath` | String | C:\DiskStressTest | - | Directory for test files |
| `-FileSizeGB` | Double | 1 | 0.1-100 | Size of each test file |
| `-ThreadCount` | Integer | 4 | 1-16 | Number of parallel I/O threads |
| `-BlockSizeKB` | Integer | 64 | 4-1024 | I/O block size in KB |
| `-EmergencyStopFile` | String | STOP_DISK_STRESS.txt | - | Create this file to stop instantly |

## 🎯 Example Scenarios

### Test Monitoring Alert (70% threshold)
```powershell
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 75 -DurationMinutes 5
```

### Test Critical Alert (90% threshold)
```powershell
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 90 -DurationMinutes 10
```

### Test Database Workload (OLTP simulation)
```powershell
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Mixed -BlockSizeKB 8 -ThreadCount 8 -FileSizeGB 2 -DurationMinutes 15
```

### Test Backup Performance
```powershell
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Write -BlockSizeKB 256 -ThreadCount 4 -FileSizeGB 5 -DurationMinutes 20
```

### Remote SQL Server Testing
```powershell
# CPU test on remote server
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 80 -SqlInstance "192.168.1.50" -DurationMinutes 10

# Disk test on different drive
.\Invoke-SqlServerDiskStress.ps1 -TestPath "D:\IOTest" -ThreadCount 8 -DurationMinutes 15
```

## 🛑 Stop Methods

| Method | How | When to Use |
|--------|-----|-------------|
| **Ctrl+C** | Press `Ctrl+C` in PowerShell window | ✅ Recommended - cleanest stop |
| **Emergency File** | `New-Item -Path "STOP_*.txt" -ItemType File` | For remote/automated stops |
| **Wait** | Do nothing | Auto-stops after duration |

## 🔒 Safety Features

### CPU Load Generator
- ✅ 95% CPU cap (prevents system lockup)
- ✅ Auto-stop timer (can't run forever)
- ✅ Emergency stop file (instant remote stop)
- ✅ Ctrl+C handler (graceful shutdown)
- ✅ Auto cleanup (closes all connections)
- ✅ Uses tempdb (no production data risk)
- ✅ Read-only queries (can't modify data)

### Disk I/O Load Generator
- ✅ Disk space validation (checks available space)
- ✅ 20% buffer requirement (ensures disk won't fill)
- ✅ Time-based auto-stop (maximum 120 minutes)
- ✅ Emergency stop file (instant stop)
- ✅ Ctrl+C handler (graceful shutdown)
- ✅ Automatic cleanup (removes all test files)
- ✅ Thread limits (maximum 16 threads)
- ✅ Isolated test directory (files in dedicated folder)

## 📊 What You'll See

### CPU Load Generator Output
```
========================================
SQL Server CPU Load Generator
========================================
Target CPU:     90%
Duration:       10 minutes
SQL Instance:   localhost
========================================

[14:30:16] Starting 7 worker threads...
[14:30:25] SQL CPU: 87.5% | Target: 90% | Elapsed: 0.2 min | Remaining: 9.8 min
[14:30:35] SQL CPU: 91.2% | Target: 90% | Elapsed: 0.3 min | Remaining: 9.7 min
```

### Disk I/O Load Generator Output
```
========================================
SQL Server Disk I/O Load Generator
========================================
I/O Type:       Mixed
Duration:       10 minutes
Test Path:      C:\DiskStressTest
File Size:      1 GB per file
Thread Count:   4
========================================

[14:30:30] IOPS: 1247 (R: 623 W: 624) | Elapsed: 0.1 min | Remaining: 9.9 min | Threads: 4
[14:30:35] IOPS: 1389 (R: 701 W: 688) | Elapsed: 0.2 min | Remaining: 9.8 min | Threads: 4
```

**Color Indicators:**
- 🟢 Green = Good performance (CPU within 5% of target, IOPS ≥ 100)
- 🟡 Yellow = Acceptable performance (CPU within 15% of target, IOPS 50-99)
- 🔴 Red = Ramping up (CPU >15% below target, IOPS < 50)

## ⚡ Quick Commands Cheat Sheet

### CPU Load Generator
```powershell
# Basic
.\Invoke-SqlServerCpuStress.ps1

# High load
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 90

# Quick test
.\Invoke-SqlServerCpuStress.ps1 -DurationMinutes 2

# Remote server
.\Invoke-SqlServerCpuStress.ps1 -SqlInstance "SERVER01"

# Full control
.\Invoke-SqlServerCpuStress.ps1 -TargetCpuPercent 85 -DurationMinutes 15 -SqlInstance "PROD-SQL\INSTANCE"
```

### Disk I/O Load Generator
```powershell
# Basic
.\Invoke-SqlServerDiskStress.ps1

# High write load
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Write -ThreadCount 8

# Quick test
.\Invoke-SqlServerDiskStress.ps1 -DurationMinutes 2

# Different drive
.\Invoke-SqlServerDiskStress.ps1 -TestPath "D:\Test"

# Full control
.\Invoke-SqlServerDiskStress.ps1 -TargetIOType Mixed -ThreadCount 8 -FileSizeGB 5 -DurationMinutes 20 -TestPath "E:\StressTest"
```

## 🚨 Emergency Stop

### Stop CPU Load Generator
```powershell
# Method 1: Ctrl+C (recommended)
# Press Ctrl+C in the PowerShell window

# Method 2: Emergency file
New-Item -Path "STOP_SQL_STRESS.txt" -ItemType File
```

### Stop Disk I/O Load Generator
```powershell
# Method 1: Ctrl+C (recommended)
# Press Ctrl+C in the PowerShell window

# Method 2: Emergency file
New-Item -Path "STOP_DISK_STRESS.txt" -ItemType File
```

## 🔧 Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| **Can't connect to SQL** | Check SQL Server is running: `Get-Service MSSQLSERVER` |
| **CPU too low** | Try higher target or check for other processes |
| **Permission error** | Run PowerShell as Administrator |
| **Script won't run** | Set execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| **Insufficient disk space** | Reduce file size or use different drive |
| **Low IOPS** | Reduce thread count for HDDs, check for disk bottlenecks |

## 📋 Pre-Flight Checklist

Before running in production:

- [ ] SQL Server is responsive
- [ ] Monitoring tools are open (SSMS, alerts)
- [ ] DBA approval obtained (if required)
- [ ] Duration is reasonable (5-15 min typical)
- [ ] Target won't cause issues (<90% CPU recommended)
- [ ] Know how to stop it (Ctrl+C)
- [ ] Not during peak business hours
- [ ] Sufficient disk space available (for disk tests)

## 📖 Detailed Documentation

For comprehensive documentation, advanced usage examples, troubleshooting guides, and best practices, see:

**[📚 SQL Server Load Testing Wiki](SqlServer-StressTesting-Wiki.md)**

## 🎯 When to Use Each Tool

| Scenario | Tool | Settings |
|----------|------|----------|
| **Monitor alert test** | CPU Load Generator | 70-80% CPU, 5 min |
| **Critical alert test** | CPU Load Generator | 90-95% CPU, 5-10 min |
| **Auto-scaling test** | CPU Load Generator | 85-90% CPU, 15-20 min |
| **Database read performance** | Disk I/O Load Generator | Read, 8KB blocks, 8 threads |
| **Database write performance** | Disk I/O Load Generator | Write, 8KB blocks, 8 threads |
| **Backup performance** | Disk I/O Load Generator | Write, 256KB blocks, 4 threads |
| **General disk performance** | Disk I/O Load Generator | Mixed, 64KB blocks, 4-8 threads |

## ⚠️ Important Notes

- **CPU Load Generator**: Read-only operations, uses tempdb by default
- **Disk I/O Load Generator**: Creates temporary test files, automatically cleans up
- Both tools include multiple safety mechanisms and automatic cleanup
- Always test in non-production environments first
- Monitor while running and be ready to stop if needed

---

**⚡ Pro Tip:** Keep this quick reference open in another window while running the scripts!

**🛡️ Safety First:** When in doubt, use lower targets and shorter durations. You can always run it again!