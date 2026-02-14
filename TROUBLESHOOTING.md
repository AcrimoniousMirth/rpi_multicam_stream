# Troubleshooting Guide

## Common Issues and Solutions

### 1. Identical Cameras - Creating Persistent Device Names

**Problem**: You have multiple identical cameras and `/dev/video0`, `/dev/video2` assignments change on reboot.

**Solution**: Create persistent device names using udev rules based on USB port location.

**Steps:**

1. **Identify your cameras and their USB ports:**
   ```bash
   ./identify_cameras.sh
   ```
   
   This will show output like:
   ```
   Device: /dev/video0
     Name: HD USB Camera
     USB Path: usb1/1-1.2
   
   Device: /dev/video2
     Name: HD USB Camera
     USB Path: usb1/1-1.3
   ```

2. **Create udev rules interactively:**
   ```bash
   sudo ./create_udev_rules.sh
   ```
   
   Or manually create `/etc/udev/rules.d/99-webcam-persistent.rules`:
   ```
   # Camera on USB port 1-1.2
   SUBSYSTEM=="video4linux", KERNELS=="1-1.2", ATTR{index}=="0", SYMLINK+="video-cam1"
   
   # Camera on USB port 1-1.3
   SUBSYSTEM=="video4linux", KERNELS=="1-1.3", ATTR{index}=="0", SYMLINK+="video-cam2"
   ```

3. **Reload udev rules:**
   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

4. **Verify the persistent names were created:**
   ```bash
   ls -l /dev/video-*
   ```
   
   You should see:
   ```
   /dev/video-cam1 -> video0
   /dev/video-cam2 -> video2
   ```

5. **Update your `config.yaml`:**
   ```yaml
   cameras:
     - name: "camera_1"
       device: "/dev/video-cam1"  # Use persistent name
       port: 8081
       # ... rest of config
   
     - name: "camera_2"
       device: "/dev/video-cam2"  # Use persistent name
       port: 8082
       # ... rest of config
   ```

6. **Restart the service:**
   ```bash
   sudo systemctl restart webcam-streamer
   ```

### 2. Port Already in Use

**Problem**: `[Errno 98] Address already in use`

**Solution:**

1. Check what's using the port:
   ```bash
   ./check_ports.sh
   # Or manually:
   sudo lsof -i :8081
   ```

2. Kill the process or restart the service:
   ```bash
   ./restart_service.sh
   ```

3. Change the port in `config.yaml` if needed

### 3. Camera Not Found

**Problem**: Camera device doesn't exist

**Solution:**

1. List all video devices:
   ```bash
   ls -l /dev/video*
   v4l2-ctl --list-devices
   ```

2. Check USB connection:
   ```bash
   lsusb
   ```

3. Check permissions:
   ```bash
   sudo usermod -a -G video $USER
   # Then logout/login or reboot
   ```

### 4. Service Fails to Start

**Problem**: Service shows "failed" or "activating (auto-restart)"

**Solution:**

1. Check the logs:
   ```bash
   sudo journalctl -u webcam-streamer -n 50
   ```

2. Try running manually to see errors:
   ```bash
   cd ~/webcam-streamer
   python3 main.py config.yaml
   ```

3. Verify config.yaml syntax:
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('config.yaml'))"
   ```

### 5. No Video Stream / Stream Not Working

**Problem**: HTTP server starts but no video shows

**Solution:**

1. Check if ffmpeg can access the camera:
   ```bash
   ffmpeg -f v4l2 -list_formats all -i /dev/video0
   ```

2. Test with different input formats in `camera_streamer.py`:
   ```python
   # Try these alternatives if 'mjpeg' doesn't work:
   '-input_format', 'yuyv422'
   # or
   '-input_format', 'yuv420p'
   ```

3. Check camera capabilities:
   ```bash
   v4l2-ctl --device=/dev/video0 --list-formats-ext
   ```

### 6. Low Frame Rate / Performance Issues

**Solution:**

- Reduce resolution in config.yaml
- Lower frame rate (15-20 fps is often sufficient)
- Reduce JPEG quality (70-80 is good balance)
- Use USB 3.0 ports if available
- Check CPU temperature: `vcgencmd measure_temp`

### 7. Wrong Device Number After Reboot

**Problem**: `/dev/video0` becomes `/dev/video2` after reboot

**Solution**: This is why you need persistent device names (see issue #1 above)
