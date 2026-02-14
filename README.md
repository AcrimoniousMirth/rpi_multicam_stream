# USB Webcam Streamer for Raspberry Pi

A lightweight multi-camera MJPEG streaming application designed for Raspberry Pi. Stream multiple USB webcams simultaneously with independent configuration for each camera.

## Features

- 🎥 **Multi-Camera Support** - Stream multiple USB cameras simultaneously
- ⚙️ **Per-Camera Configuration** - Individual settings for resolution, framerate, rotation, quality, and port
- 🚀 **Auto-Start at Boot** - Systemd integration for automatic startup
- 🪶 **Lightweight** - Uses ffmpeg for efficient video processing
- 🌐 **Web Interface** - Simple HTML viewer for each camera stream
- 📝 **Comprehensive Logging** - Configurable logging levels and file output

## Requirements

### Hardware
- Raspberry Pi (any model with USB ports)
- One or more USB webcams
- Network connection

### Software
- Raspberry Pi OS (Raspbian)
- Python 3.7+
- ffmpeg
- systemd (included in Raspberry Pi OS)

## Installation

1. **Transfer files to your Raspberry Pi:**
   ```bash
   # On your computer, from this directory:
   scp -r * pi@<your-pi-ip>:~/webcam-streamer/
   ```

2. **SSH into your Raspberry Pi:**
   ```bash
   ssh pi@<your-pi-ip>
   ```

3. **Run the installation script:**
   ```bash
   cd ~/webcam-streamer
   chmod +x install.sh
   ./install.sh
   ```

The installation script will:
- Install required system packages (ffmpeg, python3)
- Install Python dependencies
- Set up the systemd service
- Enable auto-start at boot
- Start the service

## Configuration

Edit the `config.yaml` file to configure your cameras:

```yaml
cameras:
  - name: "camera_1"
    device: "/dev/video0"     # Camera device path
    port: 8081                # HTTP port for this camera
    resolution:
      width: 1920
      height: 1080
    framerate: 30             # Frames per second
    rotation: 0               # Rotation in degrees: 0, 90, 180, 270
    quality: 80               # JPEG quality (1-100)

  - name: "camera_2"
    device: "/dev/video2"
    port: 8082
    resolution:
      width: 1280
      height: 720
    framerate: 30
    rotation: 0
    quality: 80

settings:
  log_level: "INFO"           # DEBUG, INFO, WARNING, ERROR
  log_file: "/var/log/webcam-streamer.log"
```

### Finding Your Camera Devices

To list available video devices:
```bash
ls -l /dev/video*
```

To get detailed information about a camera:
```bash
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

### After Changing Configuration

Restart the service to apply changes:
```bash
sudo systemctl restart webcam-streamer
```

## Usage

### Accessing Camera Streams

Once installed and running, access your camera streams via a web browser:

- **Camera 1**: `http://<raspberry-pi-ip>:8081/`
- **Camera 2**: `http://<raspberry-pi-ip>:8082/`

For direct MJPEG stream (e.g., for VLC or another application):
- **Camera 1**: `http://<raspberry-pi-ip>:8081/stream`
- **Camera 2**: `http://<raspberry-pi-ip>:8082/stream`

### Service Management

```bash
# Check service status
sudo systemctl status webcam-streamer

# View live logs
sudo journalctl -u webcam-streamer -f

# Restart service
sudo systemctl restart webcam-streamer

# Stop service
sudo systemctl stop webcam-streamer

# Start service
sudo systemctl start webcam-streamer

# Disable auto-start
sudo systemctl disable webcam-streamer

# Enable auto-start
sudo systemctl enable webcam-streamer
```

## Troubleshooting

### Camera Not Found

If a camera isn't detected:

1. Check if the device exists:
   ```bash
   ls -l /dev/video*
   ```

2. Check camera permissions:
   ```bash
   sudo usermod -a -G video pi
   ```
   Then reboot.

3. Try a different USB port or hub

### Low Frame Rate

If you're experiencing low frame rates:

- Reduce resolution in `config.yaml`
- Lower the framerate setting
- Reduce JPEG quality
- Check USB bandwidth (USB 2.0 vs 3.0)
- Ensure your Raspberry Pi isn't thermal throttling

### Port Already in Use

If you get a "port already in use" error:

1. Check what's using the port:
   ```bash
   sudo lsof -i :8081
   ```

2. Change the port number in `config.yaml`

### Service Won't Start

Check the logs for detailed error messages:
```bash
sudo journalctl -u webcam-streamer -n 50
```

### MJPEG Format Not Supported

Some cameras don't support native MJPEG. If you see format errors:

Edit `camera_streamer.py` and change the input format:
```python
# Change from:
'-input_format', 'mjpeg',

# To:
'-input_format', 'yuyv422',  # or 'yuv420p'
```

## Performance Tips

1. **Resolution**: Lower resolutions use less CPU and bandwidth
2. **Frame Rate**: 15-30 fps is usually sufficient for monitoring
3. **Quality**: JPEG quality of 70-80 provides good balance
4. **Multiple Cameras**: Consider using USB 3.0 hub for multiple high-res cameras
5. **Cooling**: Ensure adequate cooling for your Raspberry Pi

## Advanced Usage

### Running Manually (for testing)

```bash
cd /home/pi/webcam-streamer
python3 main.py config.yaml
```

### Custom Configuration File

```bash
python3 main.py /path/to/custom-config.yaml
```

### Embedding in Other Applications

Use the MJPEG stream URL in any application that supports MJPEG:

- OBS Studio: Add "Media Source" with the stream URL
- VLC: Open Network Stream
- Home Assistant: MJPEG camera integration

## Uninstallation

To remove the webcam streamer:

```bash
cd ~/webcam-streamer
chmod +x uninstall.sh
./uninstall.sh
```

## License

This project is provided as-is for personal and educational use.

## Support

For issues or questions:
1. Check the logs: `sudo journalctl -u webcam-streamer -f`
2. Verify configuration: `cat /home/pi/webcam-streamer/config.yaml`
3. Test camera: `ffmpeg -f v4l2 -list_formats all -i /dev/video0`
