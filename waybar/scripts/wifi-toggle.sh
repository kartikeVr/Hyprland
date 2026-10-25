#!/bin/bash
APP="/home/stammererone/.cargo/bin/wifi_manager"

if pgrep -f "$APP" > /dev/null 2>&1; then
    pkill -f "$APP"
else
    "$APP" &
fi
