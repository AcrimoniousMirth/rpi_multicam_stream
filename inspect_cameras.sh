#!/bin/bash

# Camera Inspection Script
# Shows detailed information about all attached USB cameras

set -e

echo "======================================================================"
echo "USB Camera Inspection Tool"
echo "======================================================================"
echo ""

# Check if v4l2-ctl is installed
if ! command -v v4l2-ctl &> /dev/null; then
    echo "ERROR: v4l2-ctl not found!"
    echo "Install with: sudo apt-get install v4l-utils"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find all video devices
video_devices=$(ls /dev/video* 2>/dev/null | grep -E '/dev/video[0-9]+$' || true)

if [ -z "$video_devices" ]; then
    echo "No video devices found!"
    exit 1
fi

device_count=$(echo "$video_devices" | wc -l)
echo -e "${GREEN}Found $device_count video device(s)${NC}"
echo ""

# Iterate through each device
for device in $video_devices; do
    echo -e "${BLUE}======================================================================"
    echo -e "Device: $device"
    echo -e "======================================================================${NC}"
    
    # Get device info
    echo -e "\n${YELLOW}[Camera Information]${NC}"
    v4l2-ctl --device=$device --info 2>/dev/null || echo "  Unable to read camera info"
    
    # Get USB path
    echo -e "\n${YELLOW}[USB Connection]${NC}"
    udev_info=$(udevadm info --name=$device --query=all 2>/dev/null)
    
    # Extract key info
    usb_path=$(echo "$udev_info" | grep "ID_PATH=" | cut -d'=' -f2)
    if [ -n "$usb_path" ]; then
        echo "  USB Path: $usb_path"
    fi
    
    usb_port=$(echo "$udev_info" | grep "DEVPATH=" | grep -o 'usb[0-9]*/[0-9-]*' | head -n1)
    if [ -n "$usb_port" ]; then
        echo "  USB Port: $usb_port"
    fi
    
    serial=$(echo "$udev_info" | grep "ID_SERIAL=" | cut -d'=' -f2)
    if [ -n "$serial" ]; then
        echo "  Serial: $serial"
    fi
    
    # Get video capabilities
    echo -e "\n${YELLOW}[Video Capabilities]${NC}"
    v4l2-ctl --device=$device --all 2>/dev/null | grep -E "(Driver|Card type|Bus info|Capabilities)" || true
    
    # Get supported formats and resolutions
    echo -e "\n${YELLOW}[Supported Formats & Resolutions]${NC}"
    formats_output=$(v4l2-ctl --device=$device --list-formats-ext 2>/dev/null)
    
    if [ -n "$formats_output" ]; then
        # Parse formats
        echo "$formats_output" | while IFS= read -r line; do
            # Format lines
            if echo "$line" | grep -q "^\["; then
                echo -e "\n  ${GREEN}$line${NC}"
            # Pixel format lines
            elif echo "$line" | grep -q "Pixel Format"; then
                echo "    $line"
            # Size lines
            elif echo "$line" | grep -q "Size:"; then
                size=$(echo "$line" | grep -o "[0-9]*x[0-9]*" | head -n1)
                echo "      Resolution: $size"
            # Frame rate lines
            elif echo "$line" | grep -q "Interval"; then
                fps=$(echo "$line" | grep -o "([0-9.]* fps)" | tr -d '()')
                if [ -n "$fps" ]; then
                    echo "        $fps"
                fi
            fi
        done
    else
        echo "  Unable to read formats"
    fi
    
    # Get current settings
    echo -e "\n${YELLOW}[Current Settings]${NC}"
    current_format=$(v4l2-ctl --device=$device --get-fmt-video 2>/dev/null)
    if [ -n "$current_format" ]; then
        echo "$current_format" | grep -E "(Width/Height|Pixel Format)" | sed 's/^/  /'
    fi
    
    # Get controls
    echo -e "\n${YELLOW}[Available Controls]${NC}"
    controls=$(v4l2-ctl --device=$device --list-ctrls 2>/dev/null)
    if [ -n "$controls" ]; then
        # Show just the control names, not values
        echo "$controls" | grep -E "^\s+(brightness|contrast|saturation|hue|white_balance|gain|exposure|focus)" | head -n 10 | sed 's/^/  /'
        control_count=$(echo "$controls" | wc -l)
        if [ "$control_count" -gt 10 ]; then
            echo "  ... and $(($control_count - 10)) more controls"
        fi
    else
        echo "  No controls available"
    fi
    
    echo ""
    echo ""
done

# Summary table
echo -e "${BLUE}======================================================================"
echo "Summary Table"
echo -e "======================================================================${NC}"
echo ""
printf "%-15s %-30s %-20s %-15s\n" "Device" "Camera Name" "USB Port" "Formats"
echo "----------------------------------------------------------------------"

for device in $video_devices; do
    # Get camera name
    name=$(v4l2-ctl --device=$device --info 2>/dev/null | grep "Card type" | cut -d':' -f2 | xargs | cut -c1-30)
    
    # Get USB port
    usb_port=$(udevadm info --name=$device --query=all 2>/dev/null | grep "DEVPATH=" | grep -o 'usb[0-9]*/[0-9-]*' | head -n1 | cut -c1-20)
    
    # Get formats
    formats=$(v4l2-ctl --device=$device --list-formats 2>/dev/null | grep -oP "'\K[A-Z0-9]+(?=')" | paste -sd "," - | cut -c1-15)
    
    printf "%-15s %-30s %-20s %-15s\n" "$device" "$name" "$usb_port" "$formats"
done

echo ""
echo -e "${GREEN}======================================================================"
echo "Recommended Configuration"
echo -e "======================================================================${NC}"
echo ""
echo "For your config.yaml, use these device paths:"
echo ""

for device in $video_devices; do
    name=$(v4l2-ctl --device=$device --info 2>/dev/null | grep "Card type" | cut -d':' -f2 | xargs)
    
    # Check if MJPEG is supported
    if v4l2-ctl --device=$device --list-formats 2>/dev/null | grep -q "MJPEG"; then
        format="mjpeg (recommended)"
    else
        format="yuyv422 or yuv420p"
    fi
    
    # Get a common resolution
    resolution=$(v4l2-ctl --device=$device --list-formats-ext 2>/dev/null | grep "Size:" | head -n1 | grep -o "[0-9]*x[0-9]*")
    
    echo "- device: \"$device\""
    echo "  name: \"$name\""
    echo "  suggested_format: $format"
    if [ -n "$resolution" ]; then
        width=$(echo $resolution | cut -d'x' -f1)
        height=$(echo $resolution | cut -d'x' -f2)
        echo "  suggested_resolution: {width: $width, height: $height}"
    fi
    echo ""
done

echo ""
echo "For help creating persistent device names, run: ./create_udev_rules.sh"
echo ""
