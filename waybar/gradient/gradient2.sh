#!/bin/bash
#!/bin/bash

# Kill any other running gradient scripts
pkill -f "hyprctl keyword general:col.active_border"

# Optional: Add a small delay to let the process terminate
sleep 0.2


SPEED=0.02
DIRECTION="clockwise"

declare -A gradients
gradients["default"]="rgba(ff9966ff) rgba(ff5e62ff) rgba(ff3c3cff) rgba(cc2b5eff) rgba(753a88ff)"

GRADIENT=${gradients["default"]}

echo "🌇 Sunset Gradient - $DIRECTION rotation"
echo "Speed: $SPEED | Press Ctrl+C to stop"
echo ""

if [ "$DIRECTION" = "counter-clockwise" ]; then
    start=360
    end=0
    step=-1
else
    start=0
    end=360
    step=1
fi

while true; do
    for angle in $(seq $start $step $end); do
        hyprctl keyword general:col.active_border "$GRADIENT ${angle}deg" 2>/dev/null
        sleep $SPEED
    done
done
