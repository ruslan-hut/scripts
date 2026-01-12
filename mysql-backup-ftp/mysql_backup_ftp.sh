#!/bin/bash

# Disable history expansion to allow special characters like '!' in passwords
set +H

#===============================================================================
# MySQL Backup and FTP Upload Script
# Run on Ubuntu server with: bash mysql_backup_ftp.sh
#===============================================================================

#-------------------------------------------------------------------------------
# CONFIGURATION - Set your credentials and settings here
#-------------------------------------------------------------------------------

# MySQL Settings
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_DB="your_database_name"            # Database to backup (leave empty for all databases)
MYSQL_USER="root"                        # MySQL username
MYSQL_PASS=""                            # MySQL password (leave empty if no password)

# FTP Settings
FTP_HOST="ftp.example.com"
FTP_PORT="21"
FTP_USER="ftp_username"
FTP_PASS="ftp_password"
FTP_REMOTE_DIR="/backups/mysql"          # Remote directory on FTP server

# Local Settings
BACKUP_DIR="/tmp/mysql_backups"          # Local temporary backup directory
DATE_FORMAT=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="mysql_backup_${DATE_FORMAT}"
KEEP_LOCAL_BACKUP="false"                # Set to "true" to keep local backup after upload

# Backup Retention Settings
ENABLE_CLEANUP="true"                    # Set to "true" to enable old backup cleanup
RETENTION_DAYS=7                         # Number of days to keep backups (delete older ones)

# Logging
LOG_FILE="/var/log/mysql_backup.log"

#-------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cleanup() {
    if [ "$KEEP_LOCAL_BACKUP" != "true" ]; then
        log "Cleaning up local backup files..."
        rm -f "${BACKUP_DIR}/${BACKUP_NAME}.sql"
        rm -f "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    fi
}

error_exit() {
    log "ERROR: $1"
    cleanup
    exit 1
}

cleanup_old_backups() {
    if [ "$ENABLE_CLEANUP" != "true" ]; then
        log "Old backup cleanup is disabled, skipping..."
        return 0
    fi

    log "Cleaning up backups older than ${RETENTION_DAYS} days from FTP server..."

    # Calculate cutoff date
    CUTOFF_DATE=$(date -d "-${RETENTION_DAYS} days" +"%Y-%m-%d")
    log "Cutoff date: ${CUTOFF_DATE}"

    # Get list of files from FTP server
    FTP_FILE_LIST=$(curl -s --user "${FTP_USER}:${FTP_PASS}" \
        "ftp://${FTP_HOST}:${FTP_PORT}${FTP_REMOTE_DIR}/" 2>&1)

    if [ $? -ne 0 ]; then
        log "WARNING: Failed to list FTP directory for cleanup"
        return 1
    fi

    # Parse and delete old backup files
    DELETED_COUNT=0
    while IFS= read -r line; do
        # Extract filename (last field in FTP listing)
        FILENAME=$(echo "$line" | awk '{print $NF}')

        # Skip if not a mysql backup file
        if [[ ! "$FILENAME" =~ ^mysql_backup_[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            continue
        fi

        # Extract date from filename (format: mysql_backup_YYYY-MM-DD_HH-MM-SS.tar.gz)
        FILE_DATE=$(echo "$FILENAME" | grep -oP '\d{4}-\d{2}-\d{2}' | head -1)

        if [ -z "$FILE_DATE" ]; then
            continue
        fi

        # Compare dates
        if [[ "$FILE_DATE" < "$CUTOFF_DATE" ]]; then
            log "Deleting old backup: ${FILENAME} (dated: ${FILE_DATE})"

            # Delete file from FTP
            curl -s --user "${FTP_USER}:${FTP_PASS}" \
                "ftp://${FTP_HOST}:${FTP_PORT}${FTP_REMOTE_DIR}/" \
                -Q "DELE ${FTP_REMOTE_DIR}/${FILENAME}" 2>&1

            if [ $? -eq 0 ]; then
                ((DELETED_COUNT++))
            else
                log "WARNING: Failed to delete ${FILENAME}"
            fi
        fi
    done <<< "$FTP_FILE_LIST"

    log "Cleanup complete. Deleted ${DELETED_COUNT} old backup(s)."
}

#-------------------------------------------------------------------------------
# MAIN SCRIPT
#-------------------------------------------------------------------------------

log "=========================================="
log "Starting MySQL backup process"
log "=========================================="

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory"

# Build mysqldump command using array to handle special characters in passwords
MYSQLDUMP_ARGS=(
    --host="${MYSQL_HOST}"
    --port="${MYSQL_PORT}"
    --single-transaction
    --routines
    --triggers
    --events
)

# Add authentication
if [ -n "$MYSQL_USER" ]; then
    MYSQLDUMP_ARGS+=(--user="${MYSQL_USER}")
fi

if [ -n "$MYSQL_PASS" ]; then
    MYSQLDUMP_ARGS+=(--password="${MYSQL_PASS}")
fi

# Determine what to backup
if [ -n "$MYSQL_DB" ]; then
    MYSQLDUMP_ARGS+=("${MYSQL_DB}")
    log "Backing up database: ${MYSQL_DB}"
else
    MYSQLDUMP_ARGS+=(--all-databases)
    log "Backing up all databases"
fi

# Execute MySQL dump
log "Creating MySQL dump..."
mysqldump "${MYSQLDUMP_ARGS[@]}" > "${BACKUP_DIR}/${BACKUP_NAME}.sql" 2>&1

if [ $? -ne 0 ]; then
    error_exit "MySQL dump failed"
fi

log "MySQL dump completed successfully"

# Compress the backup
log "Compressing backup..."
cd "$BACKUP_DIR" || error_exit "Failed to change to backup directory"
tar -czvf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}.sql" 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
    error_exit "Backup compression failed"
fi

BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log "Backup compressed: ${BACKUP_FILE} (${BACKUP_SIZE})"

# Upload to FTP server
log "Uploading backup to FTP server..."

# Create remote directory if it doesn't exist and upload file
curl --ftp-create-dirs \
     --user "${FTP_USER}:${FTP_PASS}" \
     --upload-file "${BACKUP_FILE}" \
     "ftp://${FTP_HOST}:${FTP_PORT}${FTP_REMOTE_DIR}/${BACKUP_NAME}.tar.gz" \
     2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error_exit "FTP upload failed"
fi

log "Backup uploaded successfully to ${FTP_HOST}${FTP_REMOTE_DIR}/${BACKUP_NAME}.tar.gz"

# Cleanup old backups from FTP server
cleanup_old_backups

# Cleanup local files
cleanup

log "=========================================="
log "Backup process completed successfully"
log "=========================================="

exit 0
