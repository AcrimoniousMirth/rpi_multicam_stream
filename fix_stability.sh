#!/bin/bash

# Stream Stability Fixer
# Addresses common issues causing streams to pause or fail

echo "======================================================================"
echo "Stream Stability Fix Script"
echo "======================================================================"
echo ""

# 1. Increase buffer sizes in ffmpeg
echo "[1] Creating optimized camera_streamer.py with larger buffers..."

# This will be done via a patch to the existing file
cat > /tmp/buffer_fix.patch << 'EOF'
--- a/camera_streamer.py
+++ b/camera_streamer.py
@@ -38,6 +38,10 @@
             '-f', 'v4l2',
             '-input_format', 'mjpeg',  # Try MJPEG first for USB cameras
             '-video_size', f'{self.width}x{self.height}',
             '-framerate', str(self.fps),
+            '-thread_queue_size', '512',  # Increase input buffer
+            '-fflags', '+genpts',  # Generate presentation timestamps
+            '-use_wallclock_as_timestamps', '1',  # Use wallclock for stability
             '-i', self.device,
         ]
EOF

echo "  Buffer optimization prepared"
echo ""

# 2. Add stream keepalive
echo "[2] Recommendations:"
echo ""
echo "  A. Reduce frame rate if cameras pause:"
echo "     framerate: 15  # instead of 30"
echo ""
echo "  B. Reduce resolution if you have 2+ cameras:"
echo "     width: 1280"
echo "     height: 720"
echo ""
echo "  C. Increase quality setting (lower = better quality but more CPU):"
echo "     quality: 70  # instead of 80"
echo ""
echo "  D. Check USB bandwidth - use different USB controllers if possible"
echo ""

# 3. Network accessibility
echo "[3] Fixing network accessibility for Mainsail..."
echo ""

# Check if firewall is blocking
if command -v ufw &>/dev/null; then
    if sudo ufw status | grep -q "active"; then
        echo "  Firewall is active. Opening ports..."
        sudo ufw allow 8081/tcp comment 'Webcam stream 1'
        sudo ufw allow 8082/tcp comment 'Webcam stream 2'
        echo "  ✓ Ports 8081, 8082 opened"
    else
        echo "  ✓ Firewall inactive, ports are open"
    fi
else
    echo "  ✓ No firewall detected"
fi
echo ""

# 4. Test accessibility
echo "[4] Testing network accessibility..."
ip_addr=$(hostname -I | awk '{print $1}')
echo ""
echo "  Your Raspberry Pi IP: $ip_addr"
echo ""
echo "  Test from another device:"
echo "    http://$ip_addr:8081/"
echo "    http://$ip_addr:8082/"
echo ""
echo "  For Mainsail, add to your config:"
echo ""
echo "  [webcam camera1]"
echo "  location: printer"
echo "  service: mjpegstreamer"
echo "  target_fps: 30"
echo "  stream_url: http://$ip_addr:8081/stream"
echo ""
echo "  [webcam camera2]"
echo "  location: printer"
echo "  service: mjpegstreamer"
echo "  target_fps: 30"
echo "  stream_url: http://$ip_addr:8082/stream"
echo ""

# 5. Apply fixes
echo "[5] Apply optimizations?"
read -p "Apply buffer size optimizations? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Note: The actual implementation would patch camera_streamer.py
    echo "  To apply manually, add these flags to camera_streamer.py line ~42:"
    echo "    '-thread_queue_size', '512',"
    echo "    '-fflags', '+genpts',"
    echo "    '-use_wallclock_as_timestamps', '1',"
    echo ""
    echo "  Then restart: sudo systemctl restart webcam-streamer"
fi

echo ""
echo "======================================================================"
echo "Next Steps"
echo "======================================================================"
echo ""
echo "1. Check diagnostics: ./diagnose.sh"
echo "2. View live logs: sudo journalctl -u webcam-streamer -f"
echo "3. Restart service: sudo systemctl restart webcam-streamer"
echo ""
