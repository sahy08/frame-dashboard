#!/usr/bin/env bash
# Regenerates photos.json when Syncthing drops new photos into /opt/slideshow.
# 10s debounce to avoid running on every file during a large batch sync.
WATCH_DIR="/opt/slideshow"
GENERATE="/opt/dashboard/generate_photos_json.py"
LOG="/opt/dashboard/watch.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

log "Watcher started"

while true; do
    # Block until a change is detected (close_write = file finished writing)
    inotifywait -r -q -e close_write,moved_to,delete "$WATCH_DIR" 2>/dev/null
    # Debounce: wait until no more changes for 10s
    while inotifywait -r -q -t 10 -e close_write,moved_to,delete "$WATCH_DIR" 2>/dev/null; do :; done
    log "Changes detected — regenerating photos.json"
    python3 "$GENERATE" >> "$LOG" 2>&1
done
