#!/bin/bash

# Refresh the development copy of the site with current production content.
# Runs manually. Overwrites files and database in the dev instance — the
# dev config files (config.php / admin/config.php) are preserved so the
# dev site keeps pointing at the dev database.

set -e
set +H

SOURCE_DIR="/var/www/html/opencart"
DEST_DIR="/var/www/html/opencart-backup"

# Production database (source)
SRC_DB_USER="darkbyrior"
SRC_DB_PASS='***'
SRC_DB_NAME="darkbyrior"

# Development database (destination) — must already exist
DEV_DB_USER="darkbyrior_dev"
DEV_DB_PASS='***'
DEV_DB_NAME="darkbyrior_dev"
DEV_DB_HOST="localhost"

# Temporary dump location
TMP_DUMP="/tmp/opencart_sync_$(date +%s).sql"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    rm -f "$TMP_DUMP"
    exit 1
}

log "=========================================="
log "OpenCart prod → dev sync"
log "Source:      $SOURCE_DIR  (db: $SRC_DB_NAME)"
log "Destination: $DEST_DIR  (db: $DEV_DB_NAME)"
log "=========================================="

# Sanity checks
[ -d "$SOURCE_DIR" ] || error_exit "Source directory $SOURCE_DIR does not exist"
[ -d "$DEST_DIR" ]   || error_exit "Destination directory $DEST_DIR does not exist"

# Confirmation — this is destructive for the dev instance
read -r -p "This will overwrite $DEST_DIR files and wipe $DEV_DB_NAME. Continue? [y/N] " ANSWER
case "$ANSWER" in
    y|Y|yes|YES) ;;
    *) log "Aborted by user"; exit 0 ;;
esac

#-------------------------------------------------------------------------------
# 1. Sync files
#-------------------------------------------------------------------------------
# --delete mirrors the source, but configs and dev-only paths are excluded
# so they survive the sync. rsync excludes are matched relative to SOURCE_DIR.
log "Syncing files with rsync..."
rsync -a --delete \
    --exclude='/config.php' \
    --exclude='/admin/config.php' \
    --exclude='/.git' \
    --exclude='/system/storage/cache/' \
    --exclude='/system/storage/logs/' \
    --exclude='/system/storage/session/' \
    "$SOURCE_DIR/" "$DEST_DIR/" \
    || error_exit "rsync failed"

log "Files synced"

#-------------------------------------------------------------------------------
# 2. Sync database
#-------------------------------------------------------------------------------
log "Dumping production database $SRC_DB_NAME..."
mysqldump \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    -u "$SRC_DB_USER" -p"$SRC_DB_PASS" \
    "$SRC_DB_NAME" > "$TMP_DUMP" \
    || error_exit "mysqldump failed"

DUMP_SIZE=$(du -h "$TMP_DUMP" | cut -f1)
log "Dump created: $TMP_DUMP ($DUMP_SIZE)"

log "Resetting dev database $DEV_DB_NAME..."
mysql -h "$DEV_DB_HOST" -u "$DEV_DB_USER" -p"$DEV_DB_PASS" \
    -e "DROP DATABASE IF EXISTS \`$DEV_DB_NAME\`; CREATE DATABASE \`$DEV_DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" \
    || error_exit "Failed to reset dev database"

log "Importing dump into $DEV_DB_NAME..."
mysql -h "$DEV_DB_HOST" -u "$DEV_DB_USER" -p"$DEV_DB_PASS" "$DEV_DB_NAME" < "$TMP_DUMP" \
    || error_exit "Import into dev database failed"

log "Database synced"

#-------------------------------------------------------------------------------
# 3. Cleanup
#-------------------------------------------------------------------------------
rm -f "$TMP_DUMP"

log "=========================================="
log "Sync completed successfully"
log "=========================================="
