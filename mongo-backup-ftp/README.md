# MongoDB Backup to FTP

A bash script that creates MongoDB backups and uploads them to an FTP server with automatic retention management.

## Features

- Full database or single database backup using `mongodump`
- Compressed archives (tar.gz)
- FTP upload with automatic directory creation
- Configurable backup retention with automatic cleanup
- Authentication support for MongoDB
- Logging to file

## Usage

1. Edit the configuration section in `mongodb_backup_ftp.sh`:
   - MongoDB connection settings (host, port, database, credentials)
   - FTP server settings (host, user, password, remote directory)
   - Retention settings (days to keep backups)

2. Run the script:
```bash
chmod +x mongodb_backup_ftp.sh
./mongodb_backup_ftp.sh
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGO_HOST` | MongoDB host | `localhost` |
| `MONGO_PORT` | MongoDB port | `27017` |
| `MONGO_DB` | Database name (empty for all) | - |
| `MONGO_USER` | MongoDB username | - |
| `MONGO_PASS` | MongoDB password | - |
| `FTP_HOST` | FTP server hostname | - |
| `FTP_USER` | FTP username | - |
| `FTP_PASS` | FTP password | - |
| `FTP_REMOTE_DIR` | Remote backup directory | `/backups/mongodb` |
| `RETENTION_DAYS` | Days to keep old backups | `7` |
| `KEEP_LOCAL_BACKUP` | Keep local copy after upload | `false` |

## Scheduling

See [CRON_SETUP.md](./CRON_SETUP.md) for cron configuration examples.

## Requirements

- `mongodump` (MongoDB Database Tools)
- `curl`
- `tar`
