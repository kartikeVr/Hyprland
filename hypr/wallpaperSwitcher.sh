#!/bin/bash

# Configuration
wallpaper_dir="$HOME/Pictures/wallpapers"
cache_dir="$HOME/.cache/wallpaper_thumbs"
mkdir -p "$cache_dir"

# Find a random file (images and videos)
file=$(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) | shuf -n 1)
[ -z "$file" ] && echo "no wallpapers found!" && exit 1

apply_theme() {
  local img=$1
  # wal -i is slow; pywal16 caches internally but generation still hits CPU.
  wal -i "$img" -q
}

# Ensure awww is running (silent check)
pgrep awww-daemon >/dev/null || awww-daemon &

if [[ "$file" =~ \.(mp4|mkv|webm)$ ]]; then
  echo "selected video: $file"
  
  # Resource Efficiency: Use a hashed thumbnail cache to avoid repeated ffmpeg extraction
  hash=$(echo -n "$file" | md5sum | cut -d' ' -f1)
  thumb="$cache_dir/$hash.png"
  
  if [ ! -f "$thumb" ]; then
    ffmpeg -y -i "$file" -vf "select=eq(n\,0)" -q:v 3 "$thumb" >/dev/null 2>&1
  fi
  
  apply_theme "$thumb"
  
  # Stop any active video wallpaper and image manager to free resources
  pkill mpvpaper 2>/dev/null
  awww clear 2>/dev/null # Clear awww to save memory if it's not needed for videos
  
  # Waybar restart (keep if needed for layer positioning on your setup)
  # killall -SIGUSR2 waybar 2>/dev/null || (pkill waybar; waybar &)
  
  # Start mpvpaper with hardware acceleration and low FPS to save CPU/GPU
  # --vd-lavc-dr=yes and --hwdec=vaapi are key for efficiency
  mpvpaper -o "--hwdec=auto-safe --vo=libmpv --loop --no-audio --really-quiet --fps=15" eDP-1 "$file" &
else
  echo "selected image: $file"
  
  # Ensure video player is closed to free GPU/CPU
  pkill mpvpaper 2>/dev/null
  
  apply_theme "$file"
  
  # awww is more efficient than swww as it's written in Rust and uses less idle RAM
  awww img "$file" --transition-type any
fi

exit 0
