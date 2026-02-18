---
title: "Immich Backup: Setting Up a Secondary Backup Strategy"
date: 2026-02-18T10:00:00+08:00
draft: false
weight: 0
tags: ["immich", "backup", "truenas", "winscp", "automation", "homelab"]
cover:
  image: "/images/immich-backup-banner.png"
  alt: "Immich Backup: WinSCP & Windows 11 - Your guide to secure local archives"
---

After [setting up Immich](https://rasyidi.skyrem.my/posts/03-understanding-react-hooks/) on my TrueNAS server and watching my photo library grow to over a terabyte, I realized I needed a proper backup strategy. My homelab setup is critical—I'm running Jellyfin for media streaming, Immich for photo backup, and OpenCloud for file storage, all on a 6TB RAID 1 array. While RAID 1 provides redundancy against drive failure, it doesn't protect against accidental deletion, corruption, or catastrophic events like fire or theft.

That's when I decided to implement a secondary backup strategy. I had an 8TB hard drive sitting in my main Windows 11 PC, and I thought: why not use it as an off-site backup destination? This article documents my complete setup—from TrueNAS dataset replication to automated Windows backup scripts using WinSCP.

## The Backup Strategy

My backup approach uses a two-tier system:

1. **TrueNAS Dataset Replication**: A weekly replication task that creates snapshots of my Immich data with a 3-day retention period. This provides quick recovery from recent mistakes.
2. **Windows PC Secondary Backup**: An automated SFTP sync that copies the replicated dataset to my Windows PC's 8TB drive, keeping 10 days of history. This protects against server failure or physical damage.

This dual approach gives me multiple layers of protection:
- **Quick recovery** from the TrueNAS snapshots (up to 3 days)
- **Extended history** on the Windows PC (up to 10 days)
- **Physical separation** between the server and backup location
- **Cost-effective** use of existing hardware

## Step 1: TrueNAS Configuration

### Creating the Backup Dataset

The first step is creating a dedicated dataset for Immich backups on TrueNAS:

1. Navigate to **Storage → Datasets** in TrueNAS Scale
2. Create a new dataset named `immich_backup`
3. Set appropriate permissions (I used the same user/group as my Immich installation)

This dataset will hold the replicated snapshots of your Immich data.

### Setting Up Periodic Snapshots

Before replication can work, you need periodic snapshots:

1. Go to **Data Protection → Periodic Snapshot Tasks**
2. Click **Add** to create a new snapshot task
3. Configure:
   - **Dataset**: Select your main Immich dataset (e.g., `immich/data`)
   - **Naming Schema**: I used `auto-%Y-%m-%d_%H-%M`
   - **Schedule**: Set to run weekly (I chose Sunday at 2 AM)
   - **Lifetime**: Set to 3 days (since we're replicating weekly, 3 days gives us overlap)

The snapshots provide point-in-time recovery and are what get replicated to the backup dataset.

### Configuring Replication

Now set up the replication task to copy snapshots to the backup dataset:

1. Navigate to **Data Protection → Replication Tasks**
2. Click **Add** to create a new replication task
3. Configure the source:
   - **Source**: Your main Immich dataset
   - **Recursive**: Enable if you have subdirectories
   - **Snapshot naming**: Use the same schema as your periodic snapshots
4. Configure the destination:
   - **Destination**: Select `immich_backup` dataset
   - **Destination snapshot**: Leave default or customize
5. Set the schedule:
   - **Schedule**: Match your snapshot schedule (weekly)
   - **Retention**: Set to 3 days to match snapshot lifetime

This ensures that every week, a fresh snapshot is created and replicated to the backup dataset, with older snapshots automatically cleaned up after 3 days.

### Enabling SSH Service

For the Windows PC to access TrueNAS via SFTP, you need to enable SSH:

1. Go to **Services → SSH**
2. Click the toggle to enable the service
3. Configure settings:
   - **TCP Port**: Default 22 (or your preferred port)
   - **Login as Root with Password**: I disabled this for security
   - **Allow Password Authentication**: Disabled (we'll use SSH keys)
   - **Allow Kerberos Authentication**: Optional, I left it disabled

4. Click **Save** to start the SSH service

**Security Note**: For production use, consider:
- Changing the default SSH port
- Restricting SSH access to specific IP addresses
- Using SSH key authentication exclusively (which we'll set up next)

## Step 2: Windows PC Setup

### Installing WinSCP

WinSCP is a free SFTP client for Windows that supports scripting, making it perfect for automated backups:

1. Download WinSCP from [winscp.net](https://winscp.net/)
2. Install with default settings
3. The installation includes `winscp.com`, a command-line interface we'll use for scripting

### Setting Up SSH Key Authentication

Using SSH keys is more secure than passwords and allows unattended automation:

1. **Generate SSH Key Pair** (if you don't have one):
   - Open PowerShell on your Windows PC
   - Run: `ssh-keygen -t rsa -b 4096 -f C:\scripts\truenas.ppk`
   - Press Enter to skip passphrase (or set one if you prefer)
   - This creates `truenas.ppk` (private key) and `truenas.ppk.pub` (public key)

2. **Convert to PuTTY Format** (WinSCP uses PuTTY format):
   - Download PuTTYgen from [putty.org](https://www.putty.org/)
   - Load your private key (`truenas.ppk`)
   - Save it again as `truenas.ppk` (this converts it to PuTTY format)

3. **Add Public Key to TrueNAS**:
   - Copy the contents of `truenas.ppk.pub`
   - SSH into TrueNAS: `ssh your-username@truenas-ip`
   - Edit `~/.ssh/authorized_keys`: `nano ~/.ssh/authorized_keys`
   - Paste your public key on a new line
   - Save and exit (`Ctrl+X`, then `Y`, then Enter)
   - Set permissions: `chmod 600 ~/.ssh/authorized_keys`

4. **Test the Connection**:
   - Open WinSCP GUI
   - Create a new session:
     - **File protocol**: SFTP
     - **Host name**: Your TrueNAS IP address
     - **User name**: Your TrueNAS username
     - **Private key file**: Browse to `C:\scripts\truenas.ppk`
   - Click **Login** to verify it works

### Creating Backup Directory Structure

Create the directory where backups will be stored:

1. Create `G:\immich-backup` (or your preferred drive/path)
2. Create `G:\immich-backup\logs` for log files
3. Ensure you have write permissions to these directories

## Step 3: Automation Scripts

Now comes the automation part. I created two scripts that work together to handle the backup process.

### The Batch Script: `run_immich_backup.bat`

This Windows batch script orchestrates the backup process with error handling and logging:

```batch
@echo off
REM ===============================
REM Immich Backup Sync (Network-Aware + Daily Log + Cleanup)
REM ===============================

REM -------- CONFIG --------
set WINSCP="C:\Program Files (x86)\WinSCP\winscp.com"
set SCRIPT=C:\scripts\immich_sync.txt
set LOG_DIR=G:\immich-backup\logs
set RETRIES=3
set KEEP_DAYS=7
set NAS_HOST=192.168.0.101

REM Create log directory if not exist
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Format date as YYYYMMDD
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set LOGDATE=%%c%%a%%b
)

set LOG=%LOG_DIR%\backup_%LOGDATE%.log

echo ===== %date% %time% START ===== >> %LOG%

REM -------- CHECK NAS REACHABILITY --------
ping -n 1 %NAS_HOST% >nul 2>&1
if errorlevel 1 (
    echo NAS %NAS_HOST% unreachable. Backup skipped. >> %LOG%
    echo ===== END ===== >> %LOG%
    exit /b 1
)

REM -------- RETRY LOOP --------
set COUNT=0
:RETRY
set /a COUNT+=1

%WINSCP% /script=%SCRIPT% /log=%LOG%
set RESULT=%ERRORLEVEL%

if %RESULT%==0 (
    echo SUCCESS on attempt %COUNT% >> %LOG%
    goto CLEANUP
)

if %COUNT% LSS %RETRIES% (
    echo RETRY %COUNT% failed... retrying >> %LOG%
    timeout /t 10 >nul
    goto RETRY
)

echo FAILED after %RETRIES% attempts >> %LOG%

:CLEANUP
echo ===== END ===== >> %LOG%

REM -------- LOG ROTATION --------
forfiles /p "%LOG_DIR%" /m *.log /d -%KEEP_DAYS% /c "cmd /c del @path"
```

**What This Script Does:**

1. **Configuration Section**: Sets all the paths and variables you might need to customize:
   - `WINSCP`: Path to WinSCP command-line executable
   - `SCRIPT`: Path to the WinSCP script file
   - `LOG_DIR`: Where to store log files
   - `RETRIES`: How many times to retry on failure
   - `KEEP_DAYS`: How long to keep log files
   - `NAS_HOST`: Your TrueNAS IP address

2. **Log Directory Creation**: Ensures the log directory exists before writing logs

3. **Date-Based Logging**: Creates a new log file each day named `backup_YYYYMMDD.log`, making it easy to track backup history

4. **Network Reachability Check**: Before attempting backup, it pings the TrueNAS server. If unreachable, it logs the failure and exits gracefully without wasting time

5. **Retry Mechanism**: If the backup fails, it retries up to 3 times with a 10-second delay between attempts. This handles temporary network issues

6. **Log Rotation**: Automatically deletes log files older than 7 days to prevent disk space issues

### The WinSCP Script: `immich_sync.txt`

This script handles the actual file synchronization:

```
# ============================
# Immich NAS → PC Fast Sync Script
# ============================

option batch abort
option confirm off
option reconnecttime 30

# Connect to NAS via SFTP
open sftp://truenas_admin@192.168.0.101/ -privatekey="C:/scripts/truenas.ppk"

option transfer binary

# ---------------------------
# NAS → PC sync
# Exclude regeneratable folders
# ---------------------------
synchronize local -criteria=time -mirror -filemask="|thumbs/;encoded-video/;cache/" "G:\immich-backup" "/mnt/storage/immich_data_backup"

# PC Cleanup: delete files older than 10 days
call cmd /c forfiles /p "G:\immich-backup" /s /m *.* /d -10 /c "cmd /c del /q @path"

# Remove empty directories
call cmd /c for /f "usebackq delims=" %d in (`dir "G:\immich-backup" /ad /s /b ^| sort /R`) do rd "%d" 2>nul

exit
```

**Script Breakdown:**

1. **WinSCP Options**:
   - `option batch abort`: Don't prompt for user input, abort on errors
   - `option confirm off`: Don't ask for confirmation on operations
   - `option reconnecttime 30`: Wait 30 seconds before reconnecting on connection loss

2. **SFTP Connection**:
   - `open sftp://...`: Connects to TrueNAS using SFTP protocol
   - Uses the private key file for authentication (no password needed)
   - Replace `truenas_admin` with your TrueNAS username
   - Replace `192.168.0.101` with your TrueNAS IP address

3. **Synchronization**:
   - `synchronize local`: Syncs from remote (NAS) to local (PC)
   - `-criteria=time`: Only sync files that are newer (time-based comparison)
   - `-mirror`: Mirror mode—deletes files on PC that don't exist on NAS
   - `-filemask="|thumbs/;encoded-video/;cache/"`: Excludes these folders:
     - `thumbs/`: Thumbnail cache (can be regenerated)
     - `encoded-video/`: Transcoded videos (can be regenerated)
     - `cache/`: General cache files (can be regenerated)
   - Local path: `G:\immich-backup` (destination on Windows PC)
   - Remote path: `/mnt/storage/immich_data_backup` (source on TrueNAS)

4. **PC Cleanup**:
   - `forfiles`: Windows command to process files older than specified days
   - `/d -10`: Files older than 10 days
   - `/s`: Recursive (all subdirectories)
   - Deletes files to prevent disk space issues

5. **Empty Directory Cleanup**:
   - Removes empty directories left after file deletion
   - Uses `sort /R` to process directories in reverse order (deepest first)

**Why Exclude Those Folders?**

The excluded folders (`thumbs`, `encoded-video`, `cache`) contain files that Immich can regenerate:
- **Thumbnails**: Generated on-demand from original photos
- **Encoded videos**: Transcoding cache, can be re-encoded when needed
- **Cache**: Temporary files that don't need backup

Excluding these saves significant storage space and backup time while still protecting your original photos and videos.

## Step 4: Scheduling the Backup

To automate the backup, use Windows Task Scheduler:

1. **Open Task Scheduler**:
   - Press `Win + R`, type `taskschd.msc`, press Enter

2. **Create Basic Task**:
   - Click **Create Basic Task** in the right panel
   - Name: "Immich Backup"
   - Description: "Automated backup of Immich data from TrueNAS"

3. **Set Trigger**:
   - Choose **Weekly**
   - Set day and time (I chose Sunday at 3 AM, after the TrueNAS replication runs)

4. **Set Action**:
   - Choose **Start a program**
   - Program/script: `C:\scripts\run_immich_backup.bat`
   - Start in: `C:\scripts`

5. **Configure Settings**:
   - Check **Run whether user is logged on or not**
   - Check **Run with highest privileges** (if needed for file operations)
   - Check **Do not store password** (if using SSH keys, you don't need password)

6. **Test the Task**:
   - Right-click the task → **Run** to test immediately
   - Check the log file to verify it worked

## Monitoring & Maintenance

### Checking Logs

The batch script creates daily log files in `G:\immich-backup\logs\`. Each log file contains:

- Start and end timestamps
- Network reachability status
- Backup success/failure status
- Retry attempts (if any)
- WinSCP output (detailed sync information)

**To check recent backups:**
```powershell
# View today's log
Get-Content "G:\immich-backup\logs\backup_$(Get-Date -Format 'yyyyMMdd').log"

# View last 5 log files
Get-ChildItem "G:\immich-backup\logs\*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### Verifying Backup Integrity

Periodically verify your backups:

1. **Check File Count**: Compare file counts between TrueNAS and Windows PC
2. **Spot Check**: Randomly open a few photos/videos from the backup to ensure they're not corrupted
3. **Storage Space**: Monitor disk usage on both systems

### Storage Space Monitoring

Set up alerts for low disk space:

1. **TrueNAS**: Configure alerts in **System → Alert Services**
2. **Windows**: Use Task Scheduler to run a disk space check script, or use built-in Windows alerts

## Troubleshooting Common Issues

### Issue 1: "NAS unreachable" in Logs

**Symptoms**: Log shows "NAS unreachable. Backup skipped."

**Possible Causes**:
- TrueNAS server is powered off or sleeping
- Network connectivity issues
- Firewall blocking ping

**Solutions**:
- Verify TrueNAS is running and accessible
- Check network connection
- Temporarily disable firewall to test
- Consider using a different network check method if ping is blocked

### Issue 2: Authentication Failures

**Symptoms**: WinSCP script fails with authentication errors

**Possible Causes**:
- SSH key permissions incorrect
- Public key not added to TrueNAS
- Wrong username or IP address

**Solutions**:
- Verify SSH key file path in script
- Re-add public key to TrueNAS `~/.ssh/authorized_keys`
- Test connection manually in WinSCP GUI first
- Check username and IP address in script

### Issue 3: Backup Takes Too Long

**Symptoms**: Backup runs for hours or doesn't complete

**Possible Causes**:
- Large amount of data to sync
- Slow network connection
- Too many files to process

**Solutions**:
- First backup will take longest (full sync)
- Subsequent backups are incremental (only changed files)
- Consider running during off-peak hours
- Check network speed between PC and TrueNAS
- Verify excluded folders are working (should reduce sync time)

### Issue 4: Disk Space Filling Up

**Symptoms**: Windows PC running out of space

**Possible Causes**:
- Cleanup script not running
- Retention period too long
- Backup includes excluded folders

**Solutions**:
- Verify cleanup commands in WinSCP script are executing
- Reduce retention period (change `/d -10` to `/d -7` for 7 days)
- Manually check what's taking up space
- Verify filemask exclusions are working

### Issue 5: Task Scheduler Not Running

**Symptoms**: Backup doesn't run automatically

**Possible Causes**:
- PC is powered off during scheduled time
- Task Scheduler service not running
- Task configuration incorrect

**Solutions**:
- Verify PC is on during backup window
- Check Task Scheduler service status
- Review task history in Task Scheduler
- Test task manually (right-click → Run)

## Why This Approach Works

After running this setup for several months, here's why I'm confident in it:

### Multiple Layers of Protection

1. **RAID 1**: Protects against single drive failure
2. **TrueNAS Snapshots**: Quick recovery from mistakes (up to 3 days)
3. **Windows PC Backup**: Extended history and physical separation (up to 10 days)

### Cost-Effective

- Uses existing hardware (no additional purchase needed)
- Leverages free, open-source tools (WinSCP, TrueNAS)
- Minimal ongoing costs (just electricity)

### Automated & Reliable

- Fully automated—set it and forget it
- Retry mechanism handles temporary failures
- Comprehensive logging for troubleshooting
- Network-aware (skips backup if server unreachable)

### Efficient

- Incremental syncs (only changed files after initial backup)
- Excludes regeneratable files (saves space and time)
- Automatic cleanup prevents disk space issues

## Lessons Learned & Best Practices

### What Works Well

1. **Weekly Schedule**: Weekly backups strike a good balance between protection and resource usage. Daily would be overkill for my use case.

2. **10-Day Retention on PC**: Gives enough history to recover from mistakes while not consuming excessive disk space.

3. **Excluding Cache Folders**: Saves significant storage space (cache can be 20-30% of total size) without losing important data.

4. **Daily Logs**: Makes troubleshooting much easier. I can quickly see when backups last ran and if there were any issues.

5. **Network Check Before Backup**: Prevents wasted time and log clutter when the server is down for maintenance.

### What Could Be Improved

1. **Email Notifications**: I'm considering adding email alerts for backup failures. Currently, I check logs manually.

2. **Backup Verification**: Automated integrity checks would be nice—comparing checksums between source and backup.

3. **Multiple Backup Locations**: For critical data, consider backing up to cloud storage as well (though this adds cost).

4. **Encryption**: For sensitive photos, consider encrypting backups at rest on the Windows PC.

### Recommendations for Others

1. **Start Simple**: Begin with manual backups, then automate once you understand the process.

2. **Test Recovery**: Periodically test restoring files from backup to ensure the process works.

3. **Monitor Regularly**: Check logs weekly to catch issues early.

4. **Document Your Setup**: Keep notes on your configuration—you'll forget details over time.

5. **Consider Your Use Case**: Adjust retention periods and schedules based on:
   - How often your data changes
   - How critical the data is
   - Available storage space
   - Network bandwidth

6. **Security First**: Always use SSH keys instead of passwords, and keep your private key secure.

## Final Thoughts

Setting up this backup strategy gave me peace of mind about my photo library. Knowing that my memories are protected across multiple layers—RAID redundancy, TrueNAS snapshots, and a secondary Windows backup—means I can focus on using Immich without worrying about data loss.

The automation makes it maintenance-free. Once configured, it runs silently in the background, and I only check in when I want to verify everything is working. The combination of TrueNAS's built-in replication features and WinSCP's scripting capabilities creates a robust, cost-effective backup solution.

**What I love about this setup:**
- Fully automated—no manual intervention needed
- Multiple layers of protection
- Uses existing hardware efficiently
- Comprehensive logging for troubleshooting
- Excludes unnecessary files to save space

**What keeps me up at night:**
- Both systems are in the same physical location (consider cloud backup for true off-site protection)
- No automated integrity verification (though I spot-check periodically)
- Windows PC must be on during backup window (consider Wake-on-LAN or always-on PC)

If you're running Immich on TrueNAS and want a reliable backup strategy without breaking the bank, this approach is worth considering. It's not the most sophisticated solution, but it's practical, reliable, and gets the job done.

---

*Have you set up a backup strategy for your Immich installation? I'd love to hear about your approach and any improvements you've made!*
