#!/usr/bin/env bash
# Regenera photos.json cuando Syncthing deposita fotos nuevas en /opt/slideshow.
# Debounce de 10s para no ejecutar durante cada archivo de un batch grande.
WATCH_DIR="/opt/slideshow"
GENERATE="/opt/dashboard/generate_photos_json.py"
LOG="/opt/dashboard/watch.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

log "Watcher iniciado"

while true; do
    # Bloquea hasta detectar cambio (close_write = archivo terminó de escribirse)
    inotifywait -r -q -e close_write,moved_to,delete "$WATCH_DIR" 2>/dev/null
    # Debounce: espera a que no haya más cambios por 10s
    while inotifywait -r -q -t 10 -e close_write,moved_to,delete "$WATCH_DIR" 2>/dev/null; do :; done
    log "Cambios detectados — regenerando photos.json"
    python3 "$GENERATE" >> "$LOG" 2>&1
done
