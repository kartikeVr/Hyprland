#!/bin/bash

# This loop runs forever, but consumes almost 0% CPU.
# It waits for a line from 'pactl subscribe'
pactl subscribe | grep --line-buffered "sink" | while read -r line; do
    
    # 1. Open the window (If it's already open, this does nothing/is instant)
    eww open volume_osd
    
    # 2. Reset the closing timer
    # We kill any existing 'sleep' timer so the window doesn't close on you
    pkill -f "sleep 2 && eww close volume_osd"
    
    # Start a new background timer to close it after 2 seconds of inactivity
    (sleep 2 && eww close volume_osd) &

done
