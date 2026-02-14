#!/bin/bash

# Simple stream viewer test
# Downloads a frame and displays info

echo "Stream Viewer Test"
echo "=================="
echo ""

test_stream() {
    port=$1
    name=$2
    
    echo "Testing $name (port $port)..."
    
    # Get a few frames
    timeout 2 curl -s http://localhost:$port/stream 2>/dev/null > /tmp/stream_$port.mjpg
    
    size=$(stat -c%s /tmp/stream_$port.mjpg 2>/dev/null || stat -f%z /tmp/stream_$port.mjpg 2>/dev/null)
    
    if [ "$size" -gt 10000 ]; then
        echo "  ✓ Received ${size} bytes"
        
        # Check for JPEG boundary
        if grep -q "jpgboundary" /tmp/stream_$port.mjpg; then
            echo "  ✓ Found multipart boundary"
        else
            echo "  ✗ No multipart boundary found"
        fi
        
        # Check for JPEG markers
        jpeg_count=$(grep -abo $'\xFF\xD8' /tmp/stream_$port.mjpg | wc -l)
        echo "  ✓ Found $jpeg_count JPEG frames"
        
        # Extract first frame
        # Find first JPEG start
        start=$(grep -abo $'\xFF\xD8' /tmp/stream_$port.mjpg | head -1 | cut -d: -f1)
        # Find first JPEG end after start
        end=$(grep -abo $'\xFF\xD9' /tmp/stream_$port.mjpg | head -1 | cut -d: -f1)
        
        if [ -n "$start" ] && [ -n "$end" ] && [ "$end" -gt "$start" ]; then
            frame_size=$((end - start + 2))
            echo "  ✓ First frame size: ${frame_size} bytes"
            
            # Extract and save first frame
            dd if=/tmp/stream_$port.mjpg of=/tmp/frame_$port.jpg bs=1 skip=$start count=$frame_size 2>/dev/null
            
            # Verify it's valid JPEG
            if file /tmp/frame_$port.jpg | grep -q "JPEG"; then
                echo "  ✓ Frame is valid JPEG"
            else
                echo "  ✗ Frame is NOT valid JPEG"
                echo "    First 16 bytes:"
                xxd -l 16 /tmp/frame_$port.jpg
            fi
        else
            echo "  ✗ Could not find complete JPEG frame"
        fi
    else
        echo "  ✗ Received only ${size} bytes (too small)"
        if [ "$size" -gt 0 ]; then
            echo "  Content:"
            head -c 200 /tmp/stream_$port.mjpg
        fi
    fi
    echo ""
}

test_stream 8081 "Camera 1"
test_stream 8082 "Camera 2"

echo "To view frames:"
echo "  Camera 1: /tmp/frame_8081.jpg"
echo "  Camera 2: /tmp/frame_8082.jpg"
echo ""
echo "Copy to your computer with:"
echo "  scp manta@192.168.0.243:/tmp/frame_*.jpg ."
