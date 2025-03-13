
# 📂 Folder Watcher Docker Container

This Docker container watches a specified directory for **new files and folders**. When it detects something new, it automatically updates the **ownership** and **permissions**, and logs actions to daily log files.

---

## 🚀 Features

- Watches a directory for newly created or moved files **and** folders
- Automatically sets:
  - Ownership (`chown`)
  - Group
  - Permissions (`chmod`)
- Logs all actions to `/logs` with daily log rotation (YYYY-MM-DD.log)
- Supports recursive directory watching (including subfolders)
- Runs 24/7 and can be configured with Docker restart policies

---

## 📁 Files

```
folder-watcher/
├── Dockerfile
└── entrypoint.sh
```

---

## 🐳 Dockerfile

```dockerfile
FROM alpine:latest

# Install inotify-tools for watching files, coreutils for chown/chmod
RUN apk add --no-cache inotify-tools bash coreutils

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh

# Make sure the script is executable
RUN chmod +x /entrypoint.sh

# Run the script when the container starts
CMD ["/entrypoint.sh"]
```

---

## ⚙️ entrypoint.sh

```bash
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
```

---

## 🛠️ Configuration (Environment Variables)

| Env Variable  | Description                               | Example    |
|---------------|-------------------------------------------|------------|
| `WATCH_DIR`   | Directory to watch inside the container   | `/watched` |
| `TARGET_USER` | User ID (or name) to set as owner         | `1000`     |
| `TARGET_GROUP`| Group ID (or name) to set as group        | `1000`     |
| `TARGET_PERMS`| Permissions to apply (octal format)       | `755`      |

---

## 🏗️ Build the Docker Image

1. Place both files (`Dockerfile` and `entrypoint.sh`) inside a directory named `folder-watcher`
2. Run this command to build the image:

```bash
docker build -t folder-watcher-env ./folder-watcher
```

---

## ▶️ Run the Container (Detached & 24/7)

Basic run example (auto-restarts on reboot/crash):

```bash
docker run -d   --restart always   -v /host/folder:/watched   -v /host/logs:/logs   -e WATCH_DIR=/watched   -e TARGET_USER=1000   -e TARGET_GROUP=1000   -e TARGET_PERMS=755   folder-watcher-env
```

### 🔧 Volume Mappings

| Host Path       | Container Path | Purpose           |
|-----------------|----------------|-------------------|
| `/host/folder`  | `/watched`     | Folder to monitor |
| `/host/logs`    | `/logs`        | Where logs are saved |

---

## 📜 Logs

Logs are automatically written to:

```
/logs/YYYY-MM-DD.log
```

### View logs on the host:

```bash
tail -f /host/logs/$(date +%Y-%m-%d).log
```

---

## 📝 Notes

- The container watches **both files and folders**
- It works recursively (monitors subdirectories)
- Permissions are applied **both** to files and directories with the same `TARGET_PERMS`

---

## 📦 Optional: Docker Compose Example

```yaml
version: '3.8'

services:
  folder-watcher:
    image: folder-watcher-env
    restart: always
    volumes:
      - /host/folder:/watched
      - /host/logs:/logs
    environment:
      WATCH_DIR: /watched
      TARGET_USER: 1000
      TARGET_GROUP: 1000
      TARGET_PERMS: 755
```

Run it:

```bash
docker-compose up -d
```

---

## 🛟 To Do / Ideas for Future Improvement

- Separate file and directory permissions (`TARGET_PERMS_FILE` vs `TARGET_PERMS_DIR`)
- Log rotation and compression
- Health checks (Docker `HEALTHCHECK` command)
- Alerts (Slack/Discord/Email notifications)

---

## 🧑‍💻 Author

Built with ❤️ by [Your Name]
