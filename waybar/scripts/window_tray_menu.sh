#!/usr/bin/env bash

# Use walker to show the dropdown menu
choice=$(echo -e "  Focus Window\n󰆴  Kill Window" |  --placeholder "Window Action")

case "$choice" in
    *Focus*)
        python3 ~/.config/waybar/scripts/apps.py --popup
        ;;
    *Kill*)
        python3 ~/.config/waybar/scripts/apps.py --kill-only
        ;;
esac
