# SQL Server CPU Stress Test - Quick Reference

Please refer to the Wiki.md for detailed documentation.

## TL;DR

A safe PowerShell script that increases SQL Server CPU to test monitoring, alerts, and auto-scaling. Auto-stops after time limit. Press Ctrl+C to stop anytime.

**Default:** 70% CPU for 5 minutes on localhost  
**Safety:** Capped at 95%, read-only queries, automatic cleanup  
**Database:** Uses tempdb by default (safe)

## Quick Start

```powershell
# Download and run with defaults
.\Stress-SqlCpu.ps1

# Custom target
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 10

# Stop anytime
Press Ctrl+C
```

## Parameter Quick Reference

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `-TargetCpuPercent` | Integer | 70 | 1-95 | Target CPU percentage |
| `-DurationMinutes` | Integer | 5 | 1-60 | How long to run (auto-stops) |
| `-SqlInstance` | String | localhost | - | SQL Server instance name |
| `-Database` | String | tempdb | - | Database to use (tempdb recommended) |
| `-EmergencyStopFile` | String | STOP_SQL_STRESS.txt | - | Create this file to stop instantly |

## Common Commands

| Scenario | Command |
|----------|---------|
| **Basic test** | `.\Stress-SqlCpu.ps1` |
| **High CPU test** | `.\Stress-SqlCpu.ps1 -TargetCpuPercent 90` |
| **Quick 2-minute test** | `.\Stress-SqlCpu.ps1 -DurationMinutes 2` |
| **Remote server** | `.\Stress-SqlCpu.ps1 -SqlInstance "SERVER\INSTANCE"` |
| **Full custom** | `.\Stress-SqlCpu.ps1 -TargetCpuPercent 85 -DurationMinutes 15 -SqlInstance "SQLSERVER01"` |

## Stop Methods

| Method | How | When to Use |
|--------|-----|-------------|
| **Ctrl+C** | Press `Ctrl+C` in PowerShell window | ✅ Recommended - cleanest stop |
| **Emergency File** | `New-Item -Path "STOP_SQL_STRESS.txt" -ItemType File` | For remote/automated stops |
| **Wait** | Do nothing | Auto-stops after duration |

## Example Scenarios

### 🎯 Test Monitoring Alert (70% threshold)
```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 75 -DurationMinutes 5
```

### 🚨 Test Critical Alert (90% threshold)
```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 10
```

### 🔄 Test Auto-Scaling
```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 85 -DurationMinutes 20
```

### 🌐 Remote SQL Server
```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 80 -SqlInstance "192.168.1.50" -DurationMinutes 10
```

### ⚡ Quick Load Spike Test
```powershell
.\Stress-SqlCpu.ps1 -TargetCpuPercent 95 -DurationMinutes 2
```

### 📊 Progressive Load Test
```powershell
# Step 1: Baseline
.\Stress-SqlCpu.ps1 -TargetCpuPercent 50 -DurationMinutes 5

# Step 2: Medium
.\Stress-SqlCpu.ps1 -TargetCpuPercent 70 -DurationMinutes 5

# Step 3: High
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90 -DurationMinutes 5
```

## What You'll See

```
========================================
SQL Server CPU Stress Test
========================================
Target CPU:     90%
Duration:       10 minutes
SQL Instance:   localhost
========================================

[14:30:16] Starting 7 worker threads...
[14:30:25] SQL CPU: 87.5% | Target: 90% | Elapsed: 0.2 min | Remaining: 9.8 min
[14:30:35] SQL CPU: 91.2% | Target: 90% | Elapsed: 0.3 min | Remaining: 9.7 min
```

**Color Indicators:**
- 🟢 Green = Within 5% of target (good)
- 🟡 Yellow = Within 15% of target (ok)
- 🔴 Red = More than 15% below (ramping up)

## Safety Features Summary

| Feature | Purpose |
|---------|---------|
| ✅ 95% CPU cap | Prevents system lockup |
| ✅ Auto-stop timer | Can't run forever |
| ✅ Emergency stop file | Instant remote stop |
| ✅ Ctrl+C handler | Graceful shutdown |
| ✅ Auto cleanup | Closes all connections |
| ✅ Uses tempdb | No production data risk |
| ✅ Read-only queries | Can't modify data |
| ✅ Connection test | Validates before starting |

## Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| **Can't connect** | Check SQL Server is running: `Get-Service MSSQLSERVER` |
| **CPU too low** | Try higher target or fewer workers running |
| **Permission error** | Run PowerShell as Administrator |
| **Script won't run** | Set execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| **Workers still running** | Kill jobs: `Get-Job \| Stop-Job; Get-Job \| Remove-Job -Force` |

## Pre-Flight Checklist

Before running in production:

- [ ] SQL Server is responsive
- [ ] Monitoring tools are open (SSMS, alerts)
- [ ] DBA approval obtained (if required)
- [ ] Duration is reasonable (5-15 min typical)
- [ ] Target CPU won't cause issues (<90% recommended)
- [ ] Know how to stop it (Ctrl+C)
- [ ] Not during peak business hours

## One-Liner Cheat Sheet

```powershell
# Basic
.\Stress-SqlCpu.ps1

# High load
.\Stress-SqlCpu.ps1 -TargetCpuPercent 90

# Quick test
.\Stress-SqlCpu.ps1 -DurationMinutes 2

# Remote server
.\Stress-SqlCpu.ps1 -SqlInstance "SERVER01"

# Full control
.\Stress-SqlCpu.ps1 -TargetCpuPercent 85 -DurationMinutes 15 -SqlInstance "PROD-SQL\INSTANCE"

# Stop immediately
# Press Ctrl+C or:
New-Item -Path "STOP_SQL_STRESS.txt" -ItemType File
```

## Performance Impact

| Metric | Impact |
|--------|--------|
| **CPU** | ⬆️ High (by design) |
| **Memory** | ⬇️ Low (~100-200 MB) |
| **Disk I/O** | ⬇️ Minimal |
| **Network** | ⬇️ Minimal |
| **Table Locks** | ⬇️ None |
| **Data Changes** | ⬇️ None (read-only) |

## When to Use

| Use Case | Target CPU | Duration |
|----------|-----------|----------|
| Monitor alert test | 70-80% | 5 min |
| Critical alert test | 90-95% | 5-10 min |
| Auto-scaling test | 85-90% | 15-20 min |
| Performance baseline | 60-70% | 10-15 min |
| Quick spike test | 90-95% | 2-3 min |
| Sustained load test | 75-85% | 20-30 min |

## What It Does NOT Do

❌ Modify any data  
❌ Create/drop tables  
❌ Lock tables  
❌ Use excessive memory  
❌ Run forever  
❌ Harm your database  
❌ Require special permissions (basic read access)  

## Monitoring While Running

**SQL Server Management Studio:**
1. Open Activity Monitor (Alt+Ctrl+A)
2. Watch Processes tab
3. Check Resource Waits tab

**Performance Monitor (perfmon):**
- Processor: % Processor Time
- SQL Server: SQL Statistics\Batch Requests/sec
- SQL Server: SQL Statistics\SQL Compilations/sec

**T-SQL Query:**
```sql
-- Watch CPU in real-time
SELECT 
    @@SERVERNAME AS Server,
    sqlserver_start_time,
    cpu_count,
    (SELECT COUNT(*) FROM sys.dm_exec_requests WHERE status = 'running') AS ActiveQueries
FROM sys.dm_os_sys_info;
```

## Emergency Contact Info

**Script Issues:**
- Check full README.md for detailed troubleshooting
- Verify SQL Server connectivity first
- Review error messages in PowerShell

**SQL Server Issues:**
- Contact your DBA team
- Check SQL Server error log
- Monitor Activity Monitor in SSMS

## Important Numbers

| Metric | Value |
|--------|-------|
| Max target CPU | 95% |
| Max duration | 60 minutes |
| Default target | 70% |
| Default duration | 5 minutes |
| Status update interval | 10 seconds |
| Emergency stop check | 500 milliseconds |
| Query duration | ~30 seconds per iteration |

## File Locations

| File | Purpose | Should Commit to Git? |
|------|---------|----------------------|
| `Stress-SqlCpu.ps1` | Main script | ✅ Yes |
| `README.md` | Full documentation | ✅ Yes |
| `QUICKSTART.md` | This file | ✅ Yes |
| `STOP_SQL_STRESS.txt` | Emergency stop trigger | ❌ No (auto-created) |
| `*.log` | Transcript logs | ❌ No (optional) |

## Need More Help?

📖 **Full Documentation:** See `README.md` for:
- Detailed parameter explanations
- Advanced usage examples
- Comprehensive troubleshooting
- Best practices and guidelines
- Integration with monitoring systems

💡 **Common Questions:**
- "Is this safe?" → Yes, read-only with multiple failsafes
- "Can I use in production?" → Yes, with approval and monitoring
- "How accurate is it?" → Typically within ±5-10% of target
- "Will it break anything?" → No, designed to be safe

## Quick Tips

💡 **Start Low:** Begin with 50-60% CPU to familiarize yourself  
💡 **Monitor:** Always watch the test with SSMS Activity Monitor  
💡 **Short Tests:** Start with 2-5 minutes, extend if needed  
💡 **Off-Hours:** Run production tests during maintenance windows  
💡 **Have Exit Plan:** Know how to stop before you start  
💡 **Document:** Keep notes on what you're testing  

## Version Info

**Script Version:** 1.0  
**PowerShell Required:** 5.1 or later  
**SQL Server Supported:** 2012+  
**Last Updated:** October 2025

---

**⚡ Pro Tip:** Keep this quick reference open in another window while running the script!

**🛡️ Safety First:** When in doubt, use lower targets and shorter durations. You can always run it again!