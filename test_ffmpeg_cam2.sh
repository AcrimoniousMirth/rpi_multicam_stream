#!/bin/bash

# Test ffmpeg directly to see the actual error

echo "Testing Camera 2 ffmpeg command directly..."
echo ""

echo "Attempting to start ffmpeg for /dev/video1..."
echo ""

# Run the exact command the app uses
timeout 3 ffmpeg \
  -f v4l2 \
  -input_format mjpeg \
  -video_size 1920x1080 \
  -framerate 30 \
  -thread_queue_size 512 \
  -i /dev/video1 \
  -c:v mjpeg \
  -q:v 20 \
  -f mpjpeg \
  -bufsize 2M \
  pipe:1 \
  > /tmp/test_cam2.mjpg 2>&1

exitcode=$?

echo "Exit code: $exitcode"
echo ""
echo "Output:"
cat /tmp/test_cam2.mjpg
echo ""
echo ""

# Also check if the device is busy
echo "Checking if /dev/video1 is in use:"
sudo lsof /dev/video1
echo ""

# Check device capabilities
echo "Checking /dev/video1 formats:"
v4l2-ctl --device=/dev/video1 --list-formats-ext 2>&1 | head -30
