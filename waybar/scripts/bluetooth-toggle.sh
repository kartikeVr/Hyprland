#!/bin/bash
APP="${HOME}/.local/bin/bluetooth-manager-app"

if pgrep -f "$APP" > /dev/null 2>&1; then
    pkill -f "$APP"
else
    "$APP" &
fi
