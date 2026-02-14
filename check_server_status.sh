#!/bin/bash

# Detailed Server Status Check
echo "Checking Python process and threads..."
echo ""

# Find the webcam-streamer python process
pid=$(pgrep -f "python3.*main.py.*config.yaml")

if [ -z "$pid" ]; then
    echo "ERROR: Main Python process not found!"
    exit 1
fi

echo "Main process PID: $pid"
echo ""

# Check threads
echo "Threads:"
ps -T -p $pid | head -20
echo ""

# Check what ports the process has open
echo "Network connections:"
sudo lsof -p $pid -a -i
echo ""

# Check if any Python process has the ports
echo "Checking ports 8081-8082:"
sudo lsof -i :8081
echo ""
sudo lsof -i :8082
echo ""

# Check ffmpeg children
echo "Child processes (ffmpeg):"
pgrep -P $pid
echo ""

# Recent errors in logs
echo "Recent errors in logs:"
sudo journalctl -u webcam-streamer --since "1 minute ago" | grep -i "error\|exception\|traceback" || echo "No errors found"
