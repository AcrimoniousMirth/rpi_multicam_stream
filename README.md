# USB Webcam Streamer for Raspberry Pi

A lightweight multi-camera MJPEG streaming application designed for Raspberry Pi. Stream multiple USB webcams simultaneously with independent configuration for each camera.

## Features

- 🎥 **Multi-Camera Support** - Stream multiple USB cameras simultaneously
- ⚙️ **Per-Camera Configuration** - Individual settings for resolution, framerate, rotation, quality, and port
- 🚀 **Auto-Start at Boot** - Systemd integration for automatic startup
- 🪶 **Lightweight** - Uses ffmpeg for efficient video processing
- 🌐 **Web Interface** - Simple HTML viewer for each camera stream
- 📝 **Comprehensive Logging** - Configurable logging levels and file output
- 👤 **Multi-User Support** - Works with any user account, not just 'pi'

## Requirements

### Hardware
- Raspberry Pi (any model with USB ports)
- One or more USB webcams
- Network connection

### Software
- Raspberry Pi OS (Raspbian) or any Linux distribution
- Python 3.7+
- ffmpeg
- systemd (included in most Linux distributions)

## Installation

### Quick Install

1. **Clone the repository:**
   ```bash
   git clone https://github.com/AcrimoniousMirth/rpi_multicam_stream.git
   cd rpi_multicam_stream
   ```

2. **Run the installation script:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

The installation script will:
- Install required system packages (ffmpeg, python3)
- Install Python dependencies
- Install files to `$HOME/webcam-streamer`
- Set up the systemd service for your user
- Enable auto-start at boot
- Start the service

### Custom Installation Directory

To install to a custom directory:
```bash
export WEBCAM_INSTALL_DIR="/path/to/your/directory"
./install.sh
```

## Configuration

Edit the `config.yaml` file in your installation directory to configure your cameras:

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

- **Camera 1**: `http://<your-ip>:8081/`
- **Camera 2**: `http://<your-ip>:8082/`

For direct MJPEG stream (e.g., for VLC or another application):
- **Camera 1**: `http://<your-ip>:8081/stream`
- **Camera 2**: `http://<your-ip>:8082/stream`

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

### Permission Denied Error

If you get "Permission denied" errors during installation:

1. **Make sure you're NOT running as root:**
   ```bash
   # Run as your regular user, NOT with sudo
   ./install.sh
   ```
   The script will ask for sudo password when needed.

2. **If your home directory doesn't exist**, create it or use a custom directory:
   ```bash
   export WEBCAM_INSTALL_DIR="/opt/webcam-streamer"
   ./install.sh
   ```

### Camera Not Found

If a camera isn't detected:

1. Check if the device exists:
   ```bash
   ls -l /dev/video*
   ```

2. Check camera permissions:
   ```bash
   sudo usermod -a -G video $USER
   ```
   Then log out and log back in (or reboot).

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
cd ~/webcam-streamer
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
cd ~/rpi_multicam_stream  # or wherever you cloned the repo
./uninstall.sh
```

## Files Overview

- `camera_streamer.py` - Core streaming engine using ffmpeg
- `main.py` - Application entry point
- `config.yaml` - Camera configuration file
- `requirements.txt` - Python dependencies
- `install.sh` - Installation script
- `uninstall.sh` - Uninstallation script
- `setup.sh` - Quick setup helper
- `webcam-streamer.service` - Systemd service template

## License

This project is provided as-is for personal and educational use.

## Contributing

Issues and pull requests welcome at https://github.com/AcrimoniousMirth/rpi_multicam_stream

## Support

For issues or questions:
1. Check the logs: `sudo journalctl -u webcam-streamer -f`
2. Verify configuration: `cat ~/webcam-streamer/config.yaml`
3. Test camera: `ffmpeg -f v4l2 -list_formats all -i /dev/video0`
4. Open an issue on GitHub
