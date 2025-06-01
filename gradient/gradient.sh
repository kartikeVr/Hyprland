 #!/bin/bash

# Save as custom-ocean.sh
#!/bin/bash

# Kill any other running gradient scripts
pkill -f "hyprctl keyword general:col.active_border"

# Optional: Add a small delay to let the process terminate
sleep 0.2

# Your existing script starts here...

# Configuration
SPEED=0.006            # Animation speed (lower = faster)
DIRECTION="clockwise"   # clockwise or counter-clockwise

# Ocean gradient variations
declare -A gradients
gradients["deep"]="rgba(001433ff) rgba(002b5cff) rgba(004285ff) rgba(0059aeff) rgba(0070d7ff) rgba(0087ffff)"
gradients["tropical"]="rgba(00ccccff) rgba(00e6e6ff) rgba(00ffffff) rgba(33ffffff) rgba(66ffffff)"
gradients["storm"]="rgba(1a1a2eff) rgba(16213eff) rgba(0f3460ff) rgba(164e83ff) rgba(1a5490ff) rgba(1e6091ff)"
gradients["crystal"]="rgba(e6f2ffff) rgba(cce6ffff) rgba(99ccffff) rgba(66b3ffff) rgba(3399ffff) rgba(0080ffff)"
gradients["default"]="rgba(003366ff) rgba(0066ccff) rgba(0099ffff) rgba(00ccffff) rgba(00ffffff)"

# Select gradient (change this to use different ocean styles)
GRADIENT=${gradients["default"]}

echo "🌊 Ocean Gradient - $DIRECTION rotation"
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

# Main animation loop
while true; do
    for angle in $(seq $start $step $end); do
        hyprctl keyword general:col.active_border "$GRADIENT ${angle}deg" 2>/dev/null
        sleep $SPEED
    done
done
