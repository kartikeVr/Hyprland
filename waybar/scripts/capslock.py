#!/usr/bin/env python3
import json
import time
from pathlib import Path

# List of possible paths for the caps lock LED brightness file, based on your system.
CAPS_LOCK_PATHS = [
    Path("/sys/class/leds/input4::capslock/brightness"),
    Path("/sys/class/leds/input3::capslock/brightness"),
]

def get_caps_lock_status():
    """Check if caps lock is active by reading the LED brightness file."""
    for path in CAPS_LOCK_PATHS:
        try:
            with open(path, 'r') as f:
                return f.read().strip() == '1'
        except (FileNotFoundError, Exception):
            continue
    return False

def print_waybar_output(status):
    """Prints Waybar-compatible JSON output."""
    output = {}
    if status:
        output = {
            "text": "󰘵",  # Nerd Font icon for Caps Lock
            "class": "on",
            "tooltip": "Caps Lock: On"
        }
    print(json.dumps(output), flush=True)

if __name__ == "__main__":
    # First, print the initial state immediately so Waybar shows the module correctly on startup.
    last_status = get_caps_lock_status()
    print_waybar_output(last_status)

    # Then, loop and only print on subsequent changes to be efficient.
    while True:
        status = get_caps_lock_status()
        if status != last_status:
            print_waybar_output(status)
            last_status = status
        time.sleep(0.2) # Check status 5 times per second
