#!/bin/bash

# Diagnose why Camera 2 isn't streaming

echo "Camera 2 Diagnostics"
echo "===================="
echo ""

echo "[1] ffmpeg processes:"
ps aux | grep ffmpeg | grep -v grep
echo ""

echo "[2] Camera 2 ffmpeg process specifically:"
ps aux | grep "video1" | grep ffmpeg | grep -v grep
if [ $? -ne 0 ]; then
    echo "  ✗ No ffmpeg process for /dev/video1 found!"
else
    echo "  ✓ ffmpeg for video1 is running"
fi
echo ""

echo "[3] Check /dev/video1 device:"
ls -l /dev/video1
v4l2-ctl --device=/dev/video1 --info 2>&1 | head -5
echo ""

echo "[4] Test /dev/video1 with ffmpeg directly:"
echo "  Testing 1 frame capture..."
timeout 3 ffmpeg -f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 30 -i /dev/video1 -vframes 1 -f null - 2>&1 | tail -5
if [ $? -eq 0 ]; then
    echo "  ✓ /dev/video1 can capture frames"
else
    echo "  ✗ /dev/video1 failed to capture"
fi
echo ""

echo "[5] Recent logs for Nozzle1 (Camera 2):"
sudo journalctl -u webcam-streamer --since "10 minutes ago" | grep "Nozzle1"
echo ""

echo "[6] Check if Camera 2 process is stuck:"
main_pid=$(pgrep -f "python3.*main.py")
echo "Main process PID: $main_pid"
echo ""
echo "Threads:"
ps -T -p $main_pid 2>/dev/null | grep -E "PID|$main_pid" | head -10
echo ""

echo "[7] Check Camera 2 stream thread directly:"
sudo gdb -p $main_pid -batch -ex "thread apply all bt" 2>/dev/null | grep -A 5 "Nozzle1\|video1" || echo "  (gdb not available or no thread info)"
echo ""

echo "[8] Manual test - read from Camera 2 HTTP server:"
echo "  Requesting /stream from localhost:8082..."
timeout 2 curl -v http://localhost:8082/stream 2>&1 | head -20
