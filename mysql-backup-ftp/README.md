# MySQL Backup to FTP

A bash script that creates MySQL backups and uploads them to an FTP server with automatic retention management.

## Features

- Full database or single database backup using `mysqldump`
- Compressed archives (tar.gz)
- FTP upload with automatic directory creation
- Configurable backup retention with automatic cleanup
- Includes stored procedures, triggers, and events
- Logging to file

## Usage

1. Edit the configuration section in `mysql_backup_ftp.sh`:
   - MySQL connection settings (host, port, database, credentials)
   - FTP server settings (host, user, password, remote directory)
   - Retention settings (days to keep backups)

2. Run the script:
```bash
chmod +x mysql_backup_ftp.sh
./mysql_backup_ftp.sh
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_HOST` | MySQL host | `localhost` |
| `MYSQL_PORT` | MySQL port | `3306` |
| `MYSQL_DB` | Database name (empty for all) | - |
| `MYSQL_USER` | MySQL username | `root` |
| `MYSQL_PASS` | MySQL password | - |
| `FTP_HOST` | FTP server hostname | - |
| `FTP_USER` | FTP username | - |
| `FTP_PASS` | FTP password | - |
| `FTP_REMOTE_DIR` | Remote backup directory | `/backups/mysql` |
| `RETENTION_DAYS` | Days to keep old backups | `7` |
| `KEEP_LOCAL_BACKUP` | Keep local copy after upload | `false` |

## Scheduling

Add to crontab for automated backups:
```bash
# Daily backup at 2:00 AM
0 2 * * * /path/to/mysql_backup_ftp.sh
```

## Requirements

- `mysqldump` (MySQL client)
- `curl`
- `tar`
