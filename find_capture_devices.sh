#!/bin/bash

# Identify which video devices are actual capture devices

echo "Identifying Video Capture Devices"
echo "=================================="
echo ""

for dev in /dev/video*[0-9]; do
    # Skip if not a character device
    [ -c "$dev" ] || continue
    
    # Try to list formats
    formats_output=$(v4l2-ctl --device=$dev --list-formats 2>&1)
    
    # Extract format names (e.g. 'MJPG', 'YUYV')
    formats=$(echo "$formats_output" | grep -oP "'\K[A-Z0-9]+(?=')" | paste -sd "," -)
    
    # Check if we actually found any formats
    if [ -z "$formats" ]; then
        echo "✗ $dev - NOT a capture device (metadata/other - no formats found)"
        echo ""
        continue
    fi
    
    # It's a capture device!
    echo "✓ $dev - VIDEO CAPTURE DEVICE"
    
    # Get camera name
    name=$(v4l2-ctl --device=$dev --info 2>/dev/null | grep "Card type" | cut -d':' -f2 | xargs)
    echo "  Name: $name"
    echo "  Formats: $formats"
    
    # Check if MJPEG is supported
    if echo "$formats" | grep -q "MJPG"; then
        echo "  ✓ Supports MJPEG"
    else
        echo "  ✗ No MJPEG support"
    fi
    echo ""
done

echo ""
echo "Summary for config.yaml:"
echo "========================"
echo ""

capture_devices=()
for dev in /dev/video*[0-9]; do
    [ -c "$dev" ] || continue
    formats_output=$(v4l2-ctl --device=$dev --list-formats 2>&1)
    formats=$(echo "$formats_output" | grep -oP "'\K[A-Z0-9]+(?=')" | paste -sd "," -)
    
    # Skip if no formats found
    if [ -z "$formats" ]; then
        continue
    fi
    
    # Check if it supports MJPEG (MJPG in v4l2-ctl)
    if echo "$formats" | grep -q "MJPG"; then
        capture_devices+=("$dev")
    fi
done

if [ ${#capture_devices[@]} -ge 2 ]; then
    echo "Use these devices in your config.yaml:"
    echo ""
    echo "Camera 1 (Nozzle0):"
    echo "  device: \"${capture_devices[0]}\""
    echo ""
    echo "Camera 2 (Nozzle1):"
    echo "  device: \"${capture_devices[1]}\""
elif [ ${#capture_devices[@]} -eq 1 ]; then
    echo "⚠ Only found 1 video capture device: ${capture_devices[0]}"
else
    echo "⚠ No MJPEG-capable video capture devices found!"
fi
