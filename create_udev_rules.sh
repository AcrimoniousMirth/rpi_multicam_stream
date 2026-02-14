#!/bin/bash

# Create udev rules for persistent camera device names
# This script helps create rules based on USB port location

set -e

echo "USB Camera - Persistent Device Name Setup"
echo "=========================================="
echo ""
echo "This script will help you create persistent device names for your cameras"
echo "based on their physical USB port location."
echo ""

# First, show current cameras
./identify_cameras.sh

echo ""
echo "Creating udev rules..."
echo ""

# Create the rules file
RULES_FILE="/etc/udev/rules.d/99-webcam-persistent.rules"

cat << 'EOF_HELP'
To create persistent names, you need to identify each camera's USB path.

Example udev rule format:
  SUBSYSTEM=="video4linux", KERNELS=="1-1.2", SYMLINK+="video-cam1"

Where:
  - KERNELS=="1-1.2" is the USB port (from "USB Path" above)
  - SYMLINK+="video-cam1" is the persistent name you want

EOF_HELP

read -p "Do you want to create udev rules interactively? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled. To create rules manually, edit: $RULES_FILE"
    exit 0
fi

# Interactive rule creation
echo ""
echo "How many cameras do you want to configure?"
read -p "Number of cameras: " num_cameras

# Start building rules
rules_content="# Persistent webcam device names\n"
rules_content+="# Created $(date)\n\n"

for ((i=1; i<=num_cameras; i++)); do
    echo ""
    echo "Camera $i:"
    read -p "  Enter USB path (e.g., usb1/1-1.2): " usb_path
    
    # Extract just the port part (e.g., 1-1.2)
    port=$(echo "$usb_path" | grep -o '[0-9]-[0-9.-]*' || echo "$usb_path")
    
    read -p "  Enter desired name (e.g., cam1 or front-camera): " cam_name
    
    # Add rule
    rules_content+="# Camera $i - USB Port $port\n"
    rules_content+="SUBSYSTEM==\"video4linux\", KERNELS==\"$port\", ATTR{index}==\"0\", SYMLINK+=\"video-$cam_name\"\n\n"
done

# Write rules to temp file first
temp_file=$(mktemp)
echo -e "$rules_content" > "$temp_file"

echo ""
echo "Generated rules:"
echo "================"
cat "$temp_file"
echo ""

read -p "Install these rules? (requires sudo) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo cp "$temp_file" "$RULES_FILE"
    sudo chmod 644 "$RULES_FILE"
    
    # Reload udev rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    echo ""
    echo "✓ Udev rules installed to $RULES_FILE"
    echo ""
    echo "Your cameras should now be available as:"
    for ((i=1; i<=num_cameras; i++)); do
        echo "  /dev/video-cam$i"
    done
    echo ""
    echo "Wait a few seconds, then check with: ls -l /dev/video-*"
    echo ""
    echo "Update your config.yaml to use these device paths:"
    echo "  device: \"/dev/video-cam1\""
    echo "  device: \"/dev/video-cam2\""
else
    echo "Rules not installed. Saved to: $temp_file"
fi

rm -f "$temp_file"
