#!/usr/bin/env python3
"""
calendar_time.py
- Emits JSON with either time or date depending on toggle stored in a tmp file.
- On --toggle toggles which is shown.
- On click the Waybar config calls --toggle which will flip between time/date.
- Includes a formatted calendar in the tooltip.
"""

import sys, json, time, os, calendar
from datetime import datetime

TOGGLE_FILE = "/tmp/waybar_calendar_time_mode"

def get_calendar_tooltip(now):
    cal = calendar.TextCalendar(calendar.SUNDAY)
    # Format month as a string
    month_str = cal.formatmonth(now.year, now.month)
    
    # Highlight current day
    day = now.day
    lines = month_str.splitlines()
    header = lines[0] # "May 2026"
    weekdays = lines[1] # "Su Mo Tu We Th Fr Sa"
    
    new_lines = [f"<b>{header}</b>", weekdays]
    
    for line in lines[2:]:
        # Standard calendar is 3 chars per day
        # We search for the day with spaces around it
        day_str = str(day)
        
        # Padded version of the day to look for
        padded_day = f" {day_str} "
        if len(day_str) == 1:
            padded_day = f"  {day_str} "
            
        # Highlight version
        highlighted = f" <span color='#ff79c6'><b>{day_str}</b></span> "
        if len(day_str) == 1:
            highlighted = f"  <span color='#ff79c6'><b>{day_str}</b></span> "

        # Add padding to line to handle edges
        extended_line = " " + line + " "
        if padded_day in extended_line:
            # We must NOT use strip() as it removes leading spaces needed for alignment
            line = extended_line.replace(padded_day, highlighted)
            # Remove the single extra spaces we added at the very start and end
            if line.startswith(" "): line = line[1:]
            if line.endswith(" "): line = line[:-1]
            
        new_lines.append(line)

    # Wrap in monospace to keep columns aligned
    return "<span font='JetBrainsMono Nerd Font 10'>" + "\n".join(new_lines) + "</span>"

def read_mode():
    if not os.path.exists(TOGGLE_FILE):
        with open(TOGGLE_FILE, "w") as f:
            f.write("time")
        return "time"
    else:
        with open(TOGGLE_FILE) as f:
            return f.read().strip()

def write_mode(m):
    with open(TOGGLE_FILE, "w") as f:
        f.write(m)

def emit():
    mode = read_mode()
    now = datetime.now()
    calendar_tooltip = get_calendar_tooltip(now)
    
    if mode == "time":
        icon = ""
        text = now.strftime("%I:%M %p")
    else:
        icon = ""
        text = now.strftime("%d-%m-%y")
    
    text = f"{icon} {text}"
    # SIMPLE TOOLTIP FOR TESTING
    print(json.dumps({"text": text, "tooltip": "TEST TOOLTIP\nLINE 2"}))
    sys.stdout.flush()

if __name__ == "__main__":
    if "--toggle" in sys.argv:
        mode = read_mode()
        write_mode("date" if mode == "time" else "time")
    else:
        emit()
