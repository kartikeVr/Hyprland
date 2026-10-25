#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import time
from pathlib import Path

STATE_FILE = Path(os.getenv("XDG_RUNTIME_DIR", "/tmp")) / "volume_state.json"
VISIBILITY_TIMEOUT = 3  # seconds to show bar after volume change

def get_volume_info():
    """Gets volume and mute status from pactl."""
    try:
        output = subprocess.check_output(["pactl", "get-sink-volume", "@DEFAULT_SINK@"], text=True)
        volume_percent = int(output.split("/")[1].strip().replace("%", ""))

        output = subprocess.check_output(["pactl", "get-sink-mute", "@DEFAULT_SINK@"], text=True)
        muted = "yes" in output.lower()

        return volume_percent, muted
    except (subprocess.CalledProcessError, FileNotFoundError):
        return 0, False

def save_state(volume, muted):
    """Saves the current volume state and timestamp."""
    with open(STATE_FILE, "w") as f:
        json.dump({"volume": volume, "muted": muted, "timestamp": time.time()}, f)

def change_volume(action):
    """Changes the volume and saves the new state, with a cap at 130%."""
    if action == "mute":
        subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
    else:
        current_volume, muted = get_volume_info()
        
        if muted and action in ["up", "down"]:
            # Unmute if volume is changed while muted
            subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "0"])

        if action == "up":
            # Cap the volume at 130%
            new_volume = min(current_volume + 5, 130)
            subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{new_volume}%"])
        elif action == "down":
            subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%"])

    # Save the final state after any change
    volume, muted = get_volume_info()
    save_state(volume, muted)

def listen():
    """Listens for state changes and prints Waybar JSON."""
    last_volume = None
    last_muted = None
    last_change_time = 0

    while True:
        volume, muted = get_volume_info()
        current_time = time.time()

        # Detect changes
        if volume != last_volume or muted != last_muted:
            last_volume = volume
            last_muted = muted
            last_change_time = current_time

        # Show bar only within visibility timeout after a change
        if current_time - last_change_time < VISIBILITY_TIMEOUT:
            if muted:
                text = " Muted"
                class_name = "muted"
            else:
                bar_length = 10
                # Scale bar to 130% max volume
                filled_length = int(bar_length * min(volume, 130) / 130)
                bar = '█' * filled_length + '─' * (bar_length - filled_length)
                text = f"{bar} {volume}%"

                if volume > 100:
                    class_name = "overdrive"
                else:
                    class_name = "visible"

            waybar_output = {
                "text": text,
                "class": class_name,
                "tooltip": f"Volume: {volume}%"
            }
        else:
            # Hidden state - output icon but keep class for styling
            if muted:
                icon = ""
            elif volume == 0:
                icon = "󰝟"
            elif volume < 33:
                icon = "󰕿"
            elif volume < 66:
                icon = "󰖀"
            else:
                icon = "󰕾"

            waybar_output = {
                "text": icon,
                "class": "hidden",
                "tooltip": f"Volume: {volume}%"
            }

        print(json.dumps(waybar_output), flush=True)
        time.sleep(0.1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Waybar Volume Manager")
    parser.add_argument("--up", action="store_true", help="Increase volume")
    parser.add_argument("--down", action="store_true", help="Decrease volume")
    parser.add_argument("--mute", action="store_true", help="Toggle mute")
    parser.add_argument("--listen", action="store_true", help="Listen for changes and output for Waybar")

    args = parser.parse_args()

    if args.up:
        change_volume("up")
    elif args.down:
        change_volume("down")
    elif args.mute:
        change_volume("mute")
    elif args.listen:
        listen()
    else:
        # Default action if no args, maybe show current state?
        volume, muted = get_volume_info()
        save_state(volume, muted)
