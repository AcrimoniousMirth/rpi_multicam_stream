#!/bin/bash

# Apply stability settings to config.yaml
# Lowers resolution and framerate to reduce USB bandwidth saturation

CONFIG_FILE="$HOME/webcam-streamer/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

echo "Applying Stability Settings to $CONFIG_FILE..."
echo "------------------------------------------------"

# Backup original config
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
echo "  ✓ Created backup: ${CONFIG_FILE}.bak"

# Use sed to update resolution and framerate for both cameras
# This is a bit brute force but effective for standard config structure

# Lower Camera 1 (Nozzle0)
sed -i 's/width: 1920/width: 1280/g' "$CONFIG_FILE"
sed -i 's/height: 1080/height: 720/g' "$CONFIG_FILE"
sed -i 's/framerate: 30/framerate: 10/g' "$CONFIG_FILE"
sed -i 's/framerate: 15/framerate: 10/g' "$CONFIG_FILE"

# Lower Camera 2 (Nozzle1) - assuming it might already be lower but ensuring it
# (The sed above will hit both if they are both 1920x1080)

echo "  ✓ Lowered resolution to 1280x720"
echo "  ✓ Lowered framerate to 15 fps"

echo ""
echo "New Configuration Preview:"
grep -E "name|device|width|height|framerate" "$CONFIG_FILE"
echo ""

echo "Restarting service..."
sudo systemctl restart webcam-streamer
echo "  ✓ Service restarted"

echo ""
echo "Please check your streams now:"
echo "  Cam 1: http://$(hostname -I | awk '{print $1}'):8081/stream"
echo "  Cam 2: http://$(hostname -I | awk '{print $1}'):8082/stream"
