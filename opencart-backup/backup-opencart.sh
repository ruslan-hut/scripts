#!/bin/bash

# Directory for storing backups
BACKUP_DIR="/var/backups/opencart"
OPENCART_DIR="/var/www/html/opencart"
LOGS_DIR="$OPENCART_DIR/upload/system/storage/logs"
mkdir -p "$BACKUP_DIR"

# Backup name with timestamp
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
SITE_BACKUP="opencart_files_$DATE.tar.gz"
DB_BACKUP="opencart_db_$DATE.sql"

# Database credentials
DB_USER="darkbyrior"    # MySQL username
DB_PASS="***"           # MySQL password
DB_NAME="darkbyrior"    # OpenCart database name

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=========================================="
log "Starting OpenCart backup process"
log "Source directory: $OPENCART_DIR"
log "Backup directory: $BACKUP_DIR"
log "=========================================="

log "Removing temporary JSON log files from $LOGS_DIR..."
DELETED_LOGS=$(find "$LOGS_DIR" -type f -name "*.json" -print -delete 2>/dev/null | wc -l)
log "Deleted $DELETED_LOGS JSON log file(s)"

# 1. Archive site files
log "Creating site files backup: $SITE_BACKUP"
tar -czf "$BACKUP_DIR/$SITE_BACKUP" -C "$OPENCART_DIR" .
SITE_SIZE=$(du -h "$BACKUP_DIR/$SITE_BACKUP" | cut -f1)
log "Site files backup created ($SITE_SIZE)"

# 2. Export database
log "Creating database backup: $DB_BACKUP"
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$DB_BACKUP"
DB_SIZE=$(du -h "$BACKUP_DIR/$DB_BACKUP" | cut -f1)
log "Database backup created ($DB_SIZE)"

# 3. Clean up old backups (keep only last 7 days)
log "Removing backups older than 7 days from $BACKUP_DIR..."
DELETED_BACKUPS=$(find "$BACKUP_DIR" -type f -mtime +7 -print -delete | wc -l)
log "Deleted $DELETED_BACKUPS old backup file(s)"

# Report current backup directory state
TOTAL_FILES=$(find "$BACKUP_DIR" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Backup directory now contains $TOTAL_FILES file(s), total size: $TOTAL_SIZE"

log "=========================================="
log "Backup process completed successfully"
log "=========================================="
