# Cron Setup Guide for MongoDB Backup Script

## Prerequisites

1. Make the script executable:
```bash
chmod +x /path/to/mongodb_backup_ftp.sh
```

2. Ensure the script has correct credentials configured.

3. Test the script manually first:
```bash
./mongodb_backup_ftp.sh
```

## Setting Up Cron Job

### Open Crontab Editor

```bash
crontab -e
```

### Cron Schedule Examples

Add one of the following lines to your crontab:

#### Every Hour (at minute 0)
```cron
0 * * * * /path/to/mongodb_backup_ftp.sh >> /var/log/mongodb_backup_cron.log 2>&1
```

#### Every 30 Minutes
```cron
*/30 * * * * /path/to/mongodb_backup_ftp.sh >> /var/log/mongodb_backup_cron.log 2>&1
```

#### Every 6 Hours
```cron
0 */6 * * * /path/to/mongodb_backup_ftp.sh >> /var/log/mongodb_backup_cron.log 2>&1
```

#### Daily at 2:00 AM
```cron
0 2 * * * /path/to/mongodb_backup_ftp.sh >> /var/log/mongodb_backup_cron.log 2>&1
```

#### Weekly (Sunday at 3:00 AM)
```cron
0 3 * * 0 /path/to/mongodb_backup_ftp.sh >> /var/log/mongodb_backup_cron.log 2>&1
```

## Cron Syntax Reference

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, Sunday=0)
│ │ │ │ │
* * * * * command
```

| Symbol | Meaning |
|--------|---------|
| `*` | Every value |
| `*/n` | Every n intervals |
| `n` | Specific value |
| `n,m` | Multiple values |
| `n-m` | Range of values |

## Verify Cron Job

List current cron jobs:
```bash
crontab -l
```

Check cron service status:
```bash
sudo systemctl status cron
```

## Troubleshooting

### Check Cron Logs
```bash
grep CRON /var/log/syslog
```

### Common Issues

1. **Script not running**: Ensure full paths are used in the script and crontab.

2. **Permission denied**: Check script has execute permission (`chmod +x`).

3. **Environment variables**: Cron runs with minimal environment. Use full paths for commands like `/usr/bin/mongodump` instead of just `mongodump`.

4. **Log file permissions**: Ensure the log directory is writable:
   ```bash
   sudo touch /var/log/mongodb_backup.log
   sudo chmod 666 /var/log/mongodb_backup.log
   ```

### Test Cron Environment

Create a test entry that runs every minute:
```cron
* * * * * /path/to/mongodb_backup_ftp.sh >> /tmp/backup_test.log 2>&1
```

Check output after a few minutes, then remove the test entry.
