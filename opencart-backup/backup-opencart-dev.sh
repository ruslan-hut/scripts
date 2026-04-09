#!/bin/bash

# OpenCart development backup — code and database only.
# Excludes images, caches, logs, sessions and other runtime/generated files
# so the archive stays small and contains only what's needed to reproduce
# the site's logic on a dev machine.

BACKUP_DIR="/var/backups/opencart-dev"
OPENCART_DIR="/var/www/html/opencart"
mkdir -p "$BACKUP_DIR"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
SITE_BACKUP="opencart_dev_files_$DATE.tar.gz"
DB_BACKUP="opencart_dev_db_$DATE.sql"

# Database credentials
DB_USER="darkbyrior"    # MySQL username
DB_PASS="***"           # MySQL password
DB_NAME="darkbyrior"    # OpenCart database name

# Paths excluded from the archive (relative to $OPENCART_DIR).
# These are user-content, generated or ephemeral files that aren't needed
# to run the site in a development environment.
EXCLUDES=(
    --exclude='./upload/image'
    --exclude='./upload/system/storage/cache'
    --exclude='./upload/system/storage/logs'
    --exclude='./upload/system/storage/session'
    --exclude='./upload/system/storage/download'
    --exclude='./upload/system/storage/upload'
    --exclude='./upload/system/storage/backup'
    --exclude='./upload/system/storage/modification'
    --exclude='./storage_prev/'
    --exclude='*.pdf'
    --exclude='*.log'
    --exclude='*.tmp'
    --exclude='./.git'
    --exclude='./node_modules'
)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=========================================="
log "Starting OpenCart DEV backup process"
log "Source directory: $OPENCART_DIR"
log "Backup directory: $BACKUP_DIR"
log "Excluding: images, caches, logs, sessions, uploads, downloads"
log "=========================================="

# 1. Archive site files (logic only)
log "Creating dev files backup: $SITE_BACKUP"
tar -czf "$BACKUP_DIR/$SITE_BACKUP" "${EXCLUDES[@]}" -C "$OPENCART_DIR" .
SITE_SIZE=$(du -h "$BACKUP_DIR/$SITE_BACKUP" | cut -f1)
log "Dev files backup created ($SITE_SIZE)"

# 2. Export database schema and data
log "Creating database backup: $DB_BACKUP"
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$DB_BACKUP"
DB_SIZE=$(du -h "$BACKUP_DIR/$DB_BACKUP" | cut -f1)
log "Database backup created ($DB_SIZE)"

# 3. Clean up old dev backups (keep only last 7 days)
log "Removing dev backups older than 7 days from $BACKUP_DIR..."
DELETED_BACKUPS=$(find "$BACKUP_DIR" -type f -mtime +7 -print -delete | wc -l)
log "Deleted $DELETED_BACKUPS old backup file(s)"

# Report current backup directory state
TOTAL_FILES=$(find "$BACKUP_DIR" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Backup directory now contains $TOTAL_FILES file(s), total size: $TOTAL_SIZE"

log "=========================================="
log "Dev backup process completed successfully"
log "=========================================="
