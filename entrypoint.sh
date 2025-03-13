#!/bin/bash

# Validate env vars
if [ -z "$WATCH_DIR" ]; then
    echo "Error: WATCH_DIR not set."
    exit 1
fi

if [ -z "$TARGET_USER" ]; then
    echo "Error: TARGET_USER not set."
    exit 1
fi

if [ -z "$TARGET_GROUP" ]; then
    echo "Error: TARGET_GROUP not set."
    exit 1
fi

if [ -z "$TARGET_PERMS" ]; then
    echo "Error: TARGET_PERMS not set."
    exit 1
fi

# Hardcoded log directory
LOG_DIR="/logs"

# Make sure directories exist
mkdir -p "$WATCH_DIR"
mkdir -p "$LOG_DIR"

# Logging function
log() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    LOGFILE="$LOG_DIR/$(date '+%Y-%m-%d').log"
    MESSAGE="$1"
    echo "[$TIMESTAMP] $MESSAGE" | tee -a "$LOGFILE"
}

log "👀 Watching directory: $WATCH_DIR (files + folders)"
log "👉 Target owner: $TARGET_USER"
log "👉 Target group: $TARGET_GROUP"
log "👉 Target permissions: $TARGET_PERMS"
log "📝 Logs are always saved to $LOG_DIR/YYYY-MM-DD.log"

# Watch the directory indefinitely for files and directories
inotifywait -m -r -e create -e moved_to --format '%w%f' "$WATCH_DIR" | while read NEWITEM
do
    # Check if item is a directory
    if [ -d "$NEWITEM" ]; then
        log "📁 New directory detected: $NEWITEM"

        # Change ownership
        chown "$TARGET_USER:$TARGET_GROUP" "$NEWITEM"
        log "✅ Changed owner to $TARGET_USER and group to $TARGET_GROUP for directory $NEWITEM"

        # Change permissions
        chmod "$TARGET_PERMS" "$NEWITEM"
        log "✅ Changed permissions to $TARGET_PERMS for directory $NEWITEM"

    # If it's a file
    elif [ -f "$NEWITEM" ]; then
        log "📄 New file detected: $NEWITEM"

        # Change ownership
        chown "$TARGET_USER:$TARGET_GROUP" "$NEWITEM"
        log "✅ Changed owner to $TARGET_USER and group to $TARGET_GROUP for file $NEWITEM"

        # Change permissions
        chmod "$TARGET_PERMS" "$NEWITEM"
        log "✅ Changed permissions to $TARGET_PERMS for file $NEWITEM"

    else
        # Fallback
        log "⚠️ Detected something else: $NEWITEM (not a regular file or directory)"
    fi

    log "🎉 Done processing $NEWITEM"
done