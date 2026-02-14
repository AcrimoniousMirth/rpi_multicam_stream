#!/bin/bash

# Identify which video devices are actual capture devices

echo "Identifying Video Capture Devices"
echo "=================================="
echo ""

for dev in /dev/video*[0-9]; do
    # Skip if not a character device
    [ -c "$dev" ] || continue
    
    # Get device capabilities
    caps=$(v4l2-ctl --device=$dev --all 2>&1 | grep "Device Caps")
    
    # Check if it's a video capture device
    if echo "$caps" | grep -q "Video Capture"; then
        echo "✓ $dev - VIDEO CAPTURE DEVICE"
        
        # Get camera name
        name=$(v4l2-ctl --device=$dev --info 2>/dev/null | grep "Card type" | cut -d':' -f2 | xargs)
        echo "  Name: $name"
        
        # Check formats
        formats=$(v4l2-ctl --device=$dev --list-formats 2>&1 | grep -oP "'\K[A-Z0-9]+(?=')" | paste -sd "," -)
        if [ -n "$formats" ]; then
            echo "  Formats: $formats"
            
            # Check if MJPEG is supported
            if echo "$formats" | grep -q "MJPEG"; then
                echo "  ✓ Supports MJPEG"
            else
                echo "  ✗ No MJPEG support"
            fi
        fi
        echo ""
    else
        echo "✗ $dev - NOT a capture device"
        echo "  Type: Metadata or other"
        echo ""
    fi
done

echo ""
echo "Summary for config.yaml:"
echo "========================"
echo ""

capture_devices=()
for dev in /dev/video*[0-9]; do
    [ -c "$dev" ] || continue
    caps=$(v4l2-ctl --device=$dev --all 2>&1 | grep "Device Caps")
    if echo "$caps" | grep -q "Video Capture"; then
        formats=$(v4l2-ctl --device=$dev --list-formats 2>&1)
        if echo "$formats" | grep -q "MJPEG"; then
            capture_devices+=("$dev")
        fi
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
