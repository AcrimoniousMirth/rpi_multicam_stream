#!/usr/bin/env python3
"""
Camera Test Script
Quick test to verify a camera works with specific settings
"""

import sys
import subprocess
import time

def test_camera(device, width, height, fps, format_type='mjpeg'):
    """Test if a camera works with given settings"""
    
    print(f"Testing {device} with:")
    print(f"  Resolution: {width}x{height}")
    print(f"  FPS: {fps}")
    print(f"  Format: {format_type}")
    print()
    
    # Build ffmpeg command
    cmd = [
        'ffmpeg',
        '-f', 'v4l2',
        '-input_format', format_type,
        '-video_size', f'{width}x{height}',
        '-framerate', str(fps),
        '-i', device,
        '-vframes', '10',  # Capture 10 frames
        '-f', 'null',
        '-'
    ]
    
    print("Running test (capturing 10 frames)...")
    print(f"Command: {' '.join(cmd)}")
    print()
    
    try:
        start = time.time()
        result = subprocess.run(
            cmd,
            capture_output=True,
            timeout=10
        )
        duration = time.time() - start
        
        if result.returncode == 0:
            print(f"✓ SUCCESS! Captured 10 frames in {duration:.2f}s")
            print(f"  Average FPS: {10/duration:.1f}")
            return True
        else:
            print("✗ FAILED!")
            error = result.stderr.decode('utf-8', errors='ignore')
            # Show relevant error lines
            for line in error.split('\n'):
                if 'error' in line.lower() or 'invalid' in line.lower():
                    print(f"  {line}")
            return False
            
    except subprocess.TimeoutExpired:
        print("✗ TIMEOUT! Camera not responding")
        return False
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return False


def main():
    if len(sys.argv) < 2:
        print("Usage: ./test_camera.sh <device> [width] [height] [fps] [format]")
        print()
        print("Examples:")
        print("  ./test_camera.sh /dev/video0")
        print("  ./test_camera.sh /dev/video0 1920 1080 30")
        print("  ./test_camera.sh /dev/video0 1280 720 30 yuyv422")
        print()
        sys.exit(1)
    
    device = sys.argv[1]
    width = int(sys.argv[2]) if len(sys.argv) > 2 else 1280
    height = int(sys.argv[3]) if len(sys.argv) > 3 else 720
    fps = int(sys.argv[4]) if len(sys.argv) > 4 else 30
    format_type = sys.argv[5] if len(sys.argv) > 5 else 'mjpeg'
    
    print("=" * 60)
    print("Camera Test Script")
    print("=" * 60)
    print()
    
    success = test_camera(device, width, height, fps, format_type)
    
    print()
    if success:
        print("This camera configuration should work in config.yaml:")
        print()
        print("  - name: \"camera_1\"")
        print(f"    device: \"{device}\"")
        print(f"    port: 8081")
        print(f"    resolution:")
        print(f"      width: {width}")
        print(f"      height: {height}")
        print(f"    framerate: {fps}")
        print(f"    rotation: 0")
        print(f"    quality: 80")
        
        if format_type != 'mjpeg':
            print()
            print(f"NOTE: This camera doesn't support MJPEG natively.")
            print(f"Edit camera_streamer.py line 39 to change:")
            print(f"  '-input_format', 'mjpeg'")
            print(f"to:")
            print(f"  '-input_format', '{format_type}'")
    else:
        print("Try different settings or run: ./inspect_cameras.sh")
        print("to see all supported formats and resolutions")
    
    print()


if __name__ == '__main__':
    main()
