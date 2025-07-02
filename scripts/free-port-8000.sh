#!/bin/bash

set -e

echo "[INFO] Checking if port 8000 is in use..."

# Find the process using port 8000
PID=$(lsof -ti :8000 | head -n 1)

if [ -z "$PID" ]; then
    echo "[OK] Port 8000 is free."
    exit 0
fi

echo "[WARNING] Port 8000 is used by process PID $PID."
PROCESS_NAME=$(ps -p $PID -o comm=)
echo "[INFO] Process name: $PROCESS_NAME"

# Attempt to stop known HTTP services
if [[ "$PROCESS_NAME" =~ ^(nginx|apache2|httpd)$ ]]; then
    echo "[INFO] Attempting to stop $PROCESS_NAME service..."

    if [[ "$PROCESS_NAME" == "nginx" ]]; then
        sudo systemctl stop nginx
        sudo systemctl disable nginx
        echo "[OK] nginx stopped and disabled."
    elif [[ "$PROCESS_NAME" =~ ^(firefox|chrome|chromium)$ ]]; then
        echo "[INFO] Port 8000 is used by a browser ($PROCESS_NAME), likely for local dev tools."
        echo "[SKIP] Not killing browser process. You can close it manually if needed."
        exit 0
    fi
else
    echo "[ERROR] Unknown process is using port 8000: $PROCESS_NAME (PID $PID)"
    echo "You can kill it manually using:"
    sudo kill -9 $PID
    echo "  sudo kill -9 $PID"
    exit 1
fi

# Recheck
sleep 1
if lsof -i :8000 > /dev/null; then
    echo "[ERROR] Port 8000 is still in use!"
    exit 1
else
    echo "[SUCCESS] Port 8000 is now free."
fi
