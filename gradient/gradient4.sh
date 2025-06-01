#!/bin/bash
#!/bin/bash

# Kill any other running gradient scripts
pkill -f "hyprctl keyword general:col.active_border"

# Optional: Add a small delay to let the process terminate
sleep 0.2


SPEED=0.02
DIRECTION="clockwise"

declare -A gradients
gradients["default"]="rgba(ff0000ff) rgba(ffff00ff) rgba(00ff00ff) rgba(00ffffff) rgba(0000ffff) rgba(ff00ffff) rgba(ff0000ff)"

GRADIENT=${gradients["default"]}

echo "🌈 RGB Gradient - $DIRECTION rotation"
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
