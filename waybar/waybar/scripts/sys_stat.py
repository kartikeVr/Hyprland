#!/usr/bin/env python3
"""
sys_stat.py
- Emits JSON with CPU/RAM/Temp icons and percentages for Waybar.
- If called with --popup it launches an external popup script (webview_plot.py).
Requirements: python3-psutil
"""

import sys
import json
import psutil
import subprocess
import os

def get_cpu_temp():
    """Gets CPU temperature (returns None if unavailable)."""
    try:
        temps = psutil.sensors_temperatures()
        if not temps:
            return None

        # Common sensor names
        for key in ("coretemp", "k10temp"):
            if key in temps and temps[key]:
                return temps[key][0].current

        # Fallback to the first available sensor reading
        for name, entries in temps.items():
            if entries:
                return entries[0].current
    except Exception:
        pass
    return None

def emit_json():
    """Emit JSON for Waybar's custom module."""
    # psutil.cpu_percent() requires a warm-up call for accurate result
    cpu_percent = psutil.cpu_percent(interval=0.1)
    ram_percent = psutil.virtual_memory().percent
    temp = get_cpu_temp()

    text = f" {cpu_percent:.0f}% |  {ram_percent:.0f}%"
    tooltip = f"CPU Usage: {cpu_percent:.0f}%\nRAM Usage: {ram_percent:.0f}%"

    if temp is not None:
        text += f" |  {temp:.0f}°C"
        tooltip += f"\nCPU Temp: {temp:.0f}°C"

    # CSS class decisions for Waybar styling
    css_class = "normal"
    if ram_percent > 90 or cpu_percent > 90 or (temp is not None and temp > 85):
        css_class = "critical"
    elif ram_percent > 80 or cpu_percent > 80 or (temp is not None and temp > 70):
        css_class = "warning"

    payload = {
        "text": text,
        "tooltip": tooltip,
        "class": css_class
    }
    print(json.dumps(payload))

def popup():
    """
    Launch external popup script (keeps GUI code out of this lightweight script).
    Adjust path if needed.
    """
    script = "/home/stammererone/.config/waybar/scripts/webview_plot.py"
    if not os.path.isfile(script):
        # fallback: try local in same folder
        script = os.path.join(os.path.dirname(__file__), "webview_plot.py")
    env = os.environ.copy()
    # ensure user's local bin is in PATH
    env["PATH"] = env.get("PATH", "") + ":/home/stammererone/.local/bin"
    try:
        # Launch detached so Waybar call doesn't block
        subprocess.Popen([script], env=env)
    except Exception as e:
        # If launch fails, print a small JSON error for debugging in journal
        err = {"text": "Popup error", "tooltip": str(e), "class": "critical"}
        print(json.dumps(err))

if __name__ == "__main__":
    # If module is called repeatedly by Waybar, do not block long on cpu_percent.
    # A short interval call above gives more accurate instantaneous reading.
    if "--popup" in sys.argv:
        popup()
    else:
        emit_json()
