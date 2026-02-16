#!/bin/bash

wallpaper_dir="$HOME/Pictures/wallpapers"
tmp_frame="/tmp/wallpaper_frame.png"

file=$(find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" \) | shuf -n 1)
[ -z "$file" ] && echo "no wallpapers found!" && exit 1

apply_theme() {
  local img=$1
  wal -i "$img"
}

# Ensure swww is running (for images)
pgrep swww || swww init

if [[ "$file" =~ \.(mp4|mkv|webm)$ ]]; then
  echo "selected video wallpaper: $file"
  ffmpeg -y -i "$file" -vf "select=eq(n\,0)" -q:v 3 "$tmp_frame" >/dev/null 2>&1
  apply_theme "$tmp_frame"
  pkill mpvpaper 2>/dev/null

  while pgrep mpvpaper >/dev/null; do
    sleep 0.1
  done
  mpvpaper -o "--hwdec=vaapi --vo=libmpv --vd-lavc-dr=yes --loop --no-audio --really-quiet --fps=15" eDP-1 "$file" &
else
  echo "selected image wallpaper: $file"
  pkill mpvpaper 2>/dev/null  # Ensure video backgrounds are fully exited
  while pgrep mpvpaper >/dev/null; do
    sleep 0.1
  done
  apply_theme "$file"
  swww img "$file" --transition-type any
fi

exit 0
