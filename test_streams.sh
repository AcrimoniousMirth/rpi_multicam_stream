#!/bin/bash

# Quick stream test - downloads a few frames to check if they're valid

echo "Testing Camera Streams"
echo "======================"
echo ""

# Test cam 1
echo "Testing Camera 1 (port 8081)..."
timeout 3 curl -s http://localhost:8081/stream > /tmp/cam1_test.mjpg 2>&1
if [ $? -eq 124 ]; then
    # Timeout is expected for streaming
    size=$(stat -f%z /tmp/cam1_test.mjpg 2>/dev/null || stat -c%s /tmp/cam1_test.mjpg 2>/dev/null)
    if [ "$size" -gt 1000 ]; then
        echo "  ✓ Camera 1 is streaming (received ${size} bytes)"
        # Check if it looks like JPEG data
        if head -c 2 /tmp/cam1_test.mjpg | xxd | grep -q "ffd8"; then
            echo "  ✓ Data starts with JPEG marker (FF D8)"
        else
            echo "  ✗ Data does NOT start with JPEG marker!"
            echo "  First 32 bytes:"
            head -c 32 /tmp/cam1_test.mjpg | xxd
        fi
    else
        echo "  ✗ Camera 1 received very little data (${size} bytes)"
    fi
else
    echo "  ✗ Camera 1 failed to connect"
fi
echo ""

# Test cam 2
echo "Testing Camera 2 (port 8082)..."
timeout 3 curl -s http://localhost:8082/stream > /tmp/cam2_test.mjpg 2>&1
if [ $? -eq 124 ]; then
    size=$(stat -f%z /tmp/cam2_test.mjpg 2>/dev/null || stat -c%s /tmp/cam2_test.mjpg 2>/dev/null)
    if [ "$size" -gt 1000 ]; then
        echo "  ✓ Camera 2 is streaming (received ${size} bytes)"
        if head -c 2 /tmp/cam2_test.mjpg | xxd | grep -q "ffd8"; then
            echo "  ✓ Data starts with JPEG marker (FF D8)"
        else
            echo "  ✗ Data does NOT start with JPEG marker!"
            echo "  First 32 bytes:"
            head -c 32 /tmp/cam2_test.mjpg | xxd
        fi
    else
        echo "  ✗ Camera 2 received very little data (${size} bytes)"
    fi
else
    echo "  ✗ Camera 2 failed to connect"
    # Try to see if port is even listening
    if curl -s http://localhost:8082/ > /dev/null 2>&1; then
        echo "  Port 8082 is responding but /stream path may be broken"
    else
        echo "  Port 8082 is not responding at all"
    fi
fi
echo ""

# Check for errors in logs
echo "Recent errors:"
sudo journalctl -u webcam-streamer --since "2 minutes ago" | grep -i "error\|exception\|traceback" | tail -10
echo ""

# Check process status
echo "Process info:"
./check_server_status.sh 2>/dev/null | head -30
