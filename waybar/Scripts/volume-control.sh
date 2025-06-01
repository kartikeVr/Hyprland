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

icon() {
  # More reliable volume parsing with grep
  vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
  mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

  if [ "$mute" = "yes" ] || [ "$vol" -eq 0 ]; then
    icon="volume-level-muted"
  elif [ "$vol" -lt 33 ]; then
    icon="volume-level-low"
  elif [ "$vol" -lt 66 ]; then
    icon="volume-level-medium"
  else
    icon="volume-level-high"
  fi
}

send_notification() {
  icon
  notify-send -a "state" -r 91190 -i "$icon" -h int:value:"$vol" "Volume: ${vol}%" -u low
}

notify_mute() {
  mute=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
  if [ "$mute" = "yes" ]; then
    notify-send -a "state" -r 91190 -i "volume-level-muted" "Volume: Muted" -u low
  else
    icon
    notify-send -a "state" -r 91190 -i "$icon" "Volume: Unmuted" -u low
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
i) action_volume i ;;
d) action_volume d ;;
m) pactl set-sink-mute @DEFAULT_SINK@ toggle && notify_mute && exit 0 ;;
*) print_error ;;
esac

send_notification
