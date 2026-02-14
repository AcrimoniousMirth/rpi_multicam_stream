#!/bin/bash

# Camera Identification Script
# Lists all video devices with their USB bus information

echo "USB Camera Device Mapping"
echo "========================="
echo ""

for device in /dev/video*; do
    # Skip if not a character device
    if [ ! -c "$device" ]; then
        continue
    fi
    
    # Get device info
    echo "Device: $device"
    
    # Get device name
    if command -v v4l2-ctl &> /dev/null; then
        name=$(v4l2-ctl --device=$device --info 2>/dev/null | grep "Card type" | cut -d':' -f2 | xargs)
        if [ -n "$name" ]; then
            echo "  Name: $name"
        fi
    fi
    
    # Get USB path
    udev_info=$(udevadm info --name=$device --query=all 2>/dev/null)
    
    # Extract USB bus info
    usb_path=$(echo "$udev_info" | grep "DEVPATH=" | grep -o '/devices/.*' | grep -o 'usb[0-9]*/[0-9-]*')
    if [ -n "$usb_path" ]; then
        echo "  USB Path: $usb_path"
    fi
    
    # Extract device path
    devpath=$(echo "$udev_info" | grep "ID_PATH=" | cut -d'=' -f2)
    if [ -n "$devpath" ]; then
        echo "  ID_PATH: $devpath"
    fi
    
    # Extract serial if available
    serial=$(echo "$udev_info" | grep "ID_SERIAL=" | cut -d'=' -f2)
    if [ -n "$serial" ]; then
        echo "  Serial: $serial"
    fi
    
    echo ""
done

echo "Instructions:"
echo "============="
echo "To create persistent device names, note the USB Path for each camera."
echo "Then run: sudo ./create_udev_rules.sh"
