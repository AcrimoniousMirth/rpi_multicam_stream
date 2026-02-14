#!/bin/bash

# Quick Setup Guide for USB Webcam Streamer
# Run this on your Raspberry Pi

echo "USB Webcam Streamer - Quick Setup"
echo "=================================="
echo ""
echo "This will install the webcam streamer and configure it to auto-start at boot."
echo ""

# Check camera devices
echo "Detected camera devices:"
ls -l /dev/video* 2>/dev/null || echo "No cameras detected!"
echo ""

read -p "Press Enter to start installation, or Ctrl+C to cancel..."

./install.sh
