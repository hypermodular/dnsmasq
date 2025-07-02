#!/bin/bash

set -e

echo "[INFO] Checking if port 53 is in use..."

# Find the process using port 53
PID=$(lsof -ti :5353 | head -n 1)

if [ -z "$PID" ]; then
    echo "[OK] Port 53 is free."
    exit 0
fi

echo "[WARNING] Port 53 is used by process PID $PID."
PROCESS_NAME=$(ps -p $PID -o comm=)
echo "[INFO] Process name: $PROCESS_NAME"

# Check if it's a known DNS service
if [[ "$PROCESS_NAME" == "systemd-resolved" || "$PROCESS_NAME" == "dnsmasq" ]]; then
    echo "[INFO] Attempting to stop $PROCESS_NAME service..."

    if [[ "$PROCESS_NAME" == "systemd-resolved" ]]; then
        sudo systemctl stop systemd-resolved
        sudo systemctl disable systemd-resolved
        echo "[OK] systemd-resolved stopped and disabled."
    elif [[ "$PROCESS_NAME" == "dnsmasq" ]]; then
        sudo systemctl stop dnsmasq
        sudo systemctl disable dnsmasq
        echo "[OK] dnsmasq stopped and disabled."
    fi
else
    echo "[ERROR] Unknown process is using port 53: $PROCESS_NAME (PID $PID)"
    echo "You can kill it manually using:"
    echo "  sudo kill -9 $PID"
    exit 1
fi

# Recheck
sleep 1
if lsof -i :5353 > /dev/null; then
    echo "[ERROR] Port 53 is still in use!"
    exit 1
else
    echo "[SUCCESS] Port 53 is now free."
fi
