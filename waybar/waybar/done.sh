#!/bin/bash

# Create the dunst config directory if it doesn't exist
mkdir -p "${HOME}/.config/dunst"

# Symlink the generated dunstrc from Pywal's cache to Dunst's config location
# Pywal will place the processed template in ~/.cache/wal/dunstrc
ln -sf "${HOME}/.cache/wal/dunstrc" "${HOME}/.config/dunst/dunstrc"

# Restart Dunst to apply the new configuration
pkill dunst
dunst &
