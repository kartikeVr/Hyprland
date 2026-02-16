#!/usr/bin/env bash

# Function to output volume as JSON for Waybar
get_volume_json() {
  vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
  mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

  # Set icon based on volume/mute
  if [ "$mute" = "yes" ] || [ "$vol" -eq 0 ]; then
    icon="󰝟"
  elif [ "$vol" -lt 33 ]; then
    icon="󰕿"
  elif [ "$vol" -lt 66 ]; then
    icon="󰖀"
  else
    icon="󰕾"
  fi

  # Return JSON format for Waybar
  echo "{\"text\": \"$vol% $icon\", \"tooltip\": \"Volume: $vol%\", \"class\": \"$mute\"}"
  exit 0
}

# Define functions
print_error() {
  cat <<"EOF"
Usage: ./volumecontrol.sh -[device] <actions>
...valid devices are...
    i   -- input device
    o   -- output device
    p   -- player application
...valid actions are...
    i   -- increase volume [+5]
    d   -- decrease volume [-5]
    m   -- mute [x]
EOF
  exit 1
}

YAD_PID_FILE="/tmp/yad_volume.pid"
TIMER_PID_FILE="/tmp/yad_volume_timer.pid"
PIPE_FILE="/tmp/yad_volume.pipe"
TIMEOUT=2

# Function to show/update the volume bar
show_volume_bar() {
    current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)

    if [ -f "$YAD_PID_FILE" ] && ps -p $(cat "$YAD_PID_FILE") > /dev/null; then
        # Yad is running, just update the value and reset the timer
        echo "$current_volume" > "$PIPE_FILE"
        if [ -f "$TIMER_PID_FILE" ]; then
            kill $(cat "$TIMER_PID_FILE") 2>/dev/null
        fi
    else
        # Yad is not running, start it
        mkfifo "$PIPE_FILE"
        yad --progress --undecorated --no-buttons --on-top --skip-taskbar --fixed \
            --title="volume_bar" --width=300 --height=30 \
            < "$PIPE_FILE" &        echo $! > "$YAD_PID_FILE"
        echo "$current_volume" > "$PIPE_FILE"
    fi

    # Start a new timer to close yad
    (
        sleep "$TIMEOUT"
        kill $(cat "$YAD_PID_FILE") 2>/dev/null
        rm -f "$YAD_PID_FILE" "$TIMER_PID_FILE" "$PIPE_FILE"
    ) &
    echo $! > "$TIMER_PID_FILE"
}

notify_mute() {
    YAD_PID_FILE="/tmp/yad_volume.pid"
    if [ -f "$YAD_PID_FILE" ] && ps -p $(cat "$YAD_PID_FILE") > /dev/null; then
        kill $(cat "$YAD_PID_FILE") 2>/dev/null
        rm -f "$YAD_PID_FILE"
    fi

    mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
    if [ "$mute" = "yes" ]; then
        yad --text="Muted" --no-buttons --undecorated --skip-taskbar --on-top --fixed --timeout=1 --title="volume_bar"
    else
        yad --text="Unmuted" --no-buttons --undecorated --skip-taskbar --on-top --fixed --timeout=1 --title="volume_bar"
    fi
}

action_volume() {
  case "${1}" in
  i)
    # Increase volume up to 150% instead of 100%
    current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
    if [ "$current_vol" -lt 150 ]; then
      new_vol=$((current_vol + 5))  # Increase by 5%
      [ "$new_vol" -gt 150 ] && new_vol=150  # Cap at 150% instead of 100%
      pactl set-sink-volume @DEFAULT_SINK@ "${new_vol}%"
    fi
    ;;
  d)
    # Decrease volume if above 0 (unchanged)
    current_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
    new_vol=$((current_vol - 5))
    [ "$new_vol" -lt 0 ] && new_vol=0
    pactl set-sink-volume @DEFAULT_SINK@ "${new_vol}%"
    ;;
  esac
}
select_output() {
  if [ "$@" ]; then
    desc="$*"
    device=$(pactl list sinks | grep -C2 -F "Description: $desc" | grep Name | cut -d: -f2 | xargs)
    if pactl set-default-sink "$device"; then
      notify-send -r 91190 "Activated: $desc"
    else
      notify-send -r 91190 "Error activating $desc"
    fi
  else
    pactl list sinks | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
  fi
}

# If no arguments provided, return volume JSON for Waybar
if [ $# -eq 0 ]; then
  get_volume_json
fi

# Evaluate device option
while getopts iops: DeviceOpt; do
  case "${DeviceOpt}" in
  i)
    nsink=$(pactl list sources short | awk '{print $2}')
    [ -z "${nsink}" ] && echo "ERROR: Input device not found..." && exit 0
    srce="--default-source"
    ;;
  o)
    nsink=$(pactl list sinks short | awk '{print $2}')
    [ -z "${nsink}" ] && echo "ERROR: Output device not found..." && exit 0
    srce=""
    ;;
  p)
    nsink=$(playerctl --list-all | grep -w "${OPTARG}")
    [ -z "${nsink}" ] && echo "ERROR: Player ${OPTARG} not active..." && exit 0
    # shellcheck disable=SC2034
    srce="${nsink}"
    ;;
  s) 
    # Select an output device
    select_output "$@"
    exit
    ;; 
  *) print_error ;; 
  esac
done

# Set default variables
shift $((OPTIND - 1))

# Execute action
case "${1}" in
i) action_volume i && show_volume_bar ;; 
d) action_volume d && show_volume_bar ;; 
m) pactl set-sink-mute @DEFAULT_SINK@ toggle && notify_mute && exit 0 ;; 
*) print_error ;; 
esac