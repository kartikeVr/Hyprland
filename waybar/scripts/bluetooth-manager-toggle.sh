#!/bin/bash
BINARY="${HOME}/.local/bin/bluetooth-manager-app"
WM_TITLE="Bluetooth Manager"

if ! pgrep -f "$BINARY" > /dev/null 2>&1; then
    "$BINARY" &
    exit 0
fi

ADDR=$(hyprctl clients 2>/dev/null | awk -v t="$WM_TITLE" '
  /^Window / {
    addr = $2
    title = $4
    gsub(/[:>]/, "", title)
    if (title == t) { print addr; exit }
  }
  /^\tclass: / {
    cls = $2
    if (cls == t || cls == "bluetooth-manager") { print addr; exit }
  }
')

if [ -z "$ADDR" ]; then
    "$BINARY" &
    exit 0
fi

ADDR="${ADDR%,}"

CURRENT_WS=$(hyprctl activeworkspace 2>/dev/null | sed -n 's/.*workspace ID \([0-9-]*\).*/\1/p')
WIN_WS=$(hyprctl clients 2>/dev/null | awk -v a="$ADDR" '
  /^Window / {
    if ($2 == a) { found=1; next }
  }
  found && /^\tworkspace: / {
    split($2, ws, " ")
    print ws[1]
    found=0
    exit
  }
')

if [ "$WIN_WS" = "-93" ] || [ "$WIN_WS" != "$CURRENT_WS" ]; then
    hyprctl dispatch movetoworkspace "$CURRENT_WS,address:$ADDR" >/dev/null 2>&1
    hyprctl dispatch focuswindow "address:$ADDR" >/dev/null 2>&1
else
    hyprctl dispatch movetoworkspace "special,address:$ADDR" >/dev/null 2>&1
fi
