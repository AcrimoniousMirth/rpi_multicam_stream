#!/bin/bash

# Webcam Streamer - Restart Script
# Stops the service, waits, and starts it again
# Useful if ports are stuck or cameras need reset

echo "Restarting webcam streamer..."

# Stop the service
sudo systemctl stop webcam-streamer

# Wait for ports to be released
sleep 2

# Start the service
sudo systemctl start webcam-streamer

# Wait for startup
sleep 2

# Show status
sudo systemctl status webcam-streamer
