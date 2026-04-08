# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Collection of standalone Bash utility scripts for Linux server administration. Each top-level directory is an independent tool — there is no shared build system, package manager, test suite, or cross-script dependencies. Target runtime is Ubuntu/Debian, typically invoked via cron.

## Structure

Each subdirectory contains one script plus its own `README.md`:

- `mongo-backup-ftp/` — `mongodump` → tar.gz → FTP upload, with retention cleanup on the remote FTP server
- `mysql-backup-ftp/` — same pattern for MySQL (`mysqldump`)
- `opencart-backup/` — local-only backup of OpenCart files + DB under `/var/backups/opencart`
- `ip-block/` — downloads country IP ranges from ipdeny.com and loads them into an `ipset` matched by an `iptables` DROP rule

## Conventions to preserve when editing

- **Credentials live inline at the top of each script** as a CONFIGURATION block. These are templates — users edit the script itself. Do not refactor to env vars or external config files unless explicitly asked.
- **Passwords use single quotes** (`FTP_PASS='...'`) and scripts run with `set +H` to disable history expansion so `!` in passwords works. Preserve both when touching the backup scripts — see commit 911ef29.
- **`mongodump`/`curl` args are built as bash arrays** (`MONGODUMP_ARGS=(...)`) to safely handle special characters in passwords. Keep this pattern; do not collapse to a single string.
- **Retention cleanup parses FTP `LIST` output with awk/regex** and issues `curl -Q "DELE ..."` per stale file. The filename regex is anchored to the `{prefix}_YYYY-MM-DD` shape produced by the same script — if you rename `BACKUP_NAME`, update the cleanup regex too.
- **`ip-block` uses the tmp-set + atomic swap pattern** (`ipset create ${NAME}_tmp` → populate → `ipset swap` → `destroy`) so the live set is never empty mid-update. Keep this; do not flush-and-refill in place.
- **Logging**: backup scripts `tee` to both stdout and `$LOG_FILE`, and check `${PIPESTATUS[0]}` (not `$?`) after piped commands. Preserve this when adding new steps.

## Running / testing

There is no test harness. Validate changes by running the script directly on a target server:

```bash
chmod +x <script>.sh
./<script>.sh
```

Cron deployment guide: `mongo-backup-ftp/CRON_SETUP.md` (applies to all backup scripts). Cron has a minimal `PATH`, so if you add new tool invocations prefer absolute paths (`/usr/bin/mongodump`, etc.) or document the PATH requirement.
