# OpenCart Backup & Sync

Bash scripts for backing up an OpenCart installation and refreshing a development copy from production. All scripts are written for a single-server setup where the main site lives at `/var/www/html/opencart` and (optionally) a dev copy at `/var/www/html/opencart-backup`.

## Scripts

| Script | Purpose |
|--------|---------|
| `backup-opencart.sh` | Full local backup — archives all site files and dumps the database to `/var/backups/opencart`. Keeps last 7 days. |
| `backup-opencart-dev.sh` | Lean "logic-only" backup for development use. Excludes images, caches, logs, sessions and other runtime/generated data. Output goes to `/var/backups/opencart-dev`. |
| `sync-opencart-to-dev.sh` | Manual prod → dev refresh. Mirrors files with `rsync --delete` (preserving dev `config.php` files) and reloads the dev database from a fresh `mysqldump` of production. Prompts for confirmation before running. |

## Usage

Edit the configuration block at the top of each script (paths, DB credentials), then:

```bash
chmod +x backup-opencart.sh backup-opencart-dev.sh sync-opencart-to-dev.sh
./backup-opencart.sh
```

`backup-opencart.sh` and `backup-opencart-dev.sh` are safe to run from cron. `sync-opencart-to-dev.sh` is interactive by design — it wipes the dev database, so it asks for confirmation and should only be run manually.

## What each script touches

### `backup-opencart.sh`
- Deletes old `*.json` log files from `upload/system/storage/logs/` before archiving
- `tar -czf` of the full OpenCart directory
- `mysqldump` of the database
- Deletes backups older than 7 days from `/var/backups/opencart`

### `backup-opencart-dev.sh`
Same shape as the full backup, but the archive excludes:
- `./upload/image` — all product/catalog/cache/invoice images
- `./upload/system/storage/{cache,logs,session,download,upload,backup,modification}` — ephemeral runtime state
- `*.log`, `*.tmp`, `*.pdf`
- `.git`, `node_modules`

The database dump is still full — development typically needs real schema and data.

### `sync-opencart-to-dev.sh`
- `rsync -a --delete` from `/var/www/html/opencart` to `/var/www/html/opencart-backup`, excluding:
  - `/config.php` and `/admin/config.php` — the dev copy keeps its own config so it stays pointed at the dev database
  - `.git`, and the `system/storage/{cache,logs,session}` runtime dirs
- `mysqldump` of the production database with `--single-transaction --routines --triggers`
- `DROP DATABASE` + `CREATE DATABASE` on the dev database, then reimports the dump
- Cleans up the temporary dump file on success or failure

Two separate credential blocks exist in the script: `SRC_DB_*` (production, source) and `DEV_DB_*` (development, destination). The dev DB user needs `DROP`/`CREATE` privileges on its own database.

## Scheduling

```cron
# Daily full backup at 3:00 AM
0 3 * * * /path/to/backup-opencart.sh >> /var/log/opencart_backup.log 2>&1

# Weekly dev backup on Sundays at 4:00 AM
0 4 * * 0 /path/to/backup-opencart-dev.sh >> /var/log/opencart_backup.log 2>&1
```

## Requirements

- `bash`, `tar`, `rsync`
- `mysqldump` and `mysql` clients
- Sufficient disk space under `/var/backups/` for the retention window
- Write access to the destination paths for the user running the script (typically `root` via cron)
