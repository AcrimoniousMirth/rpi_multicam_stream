#!/bin/bash

# Quick fix script - Pull latest code and restart service

echo "Pulling latest code..."
git pull

echo ""
echo "Restarting webcam streamer service..."
sudo systemctl restart webcam-streamer

echo ""
echo "Waiting for service to start..."
sleep 3

echo ""
echo "Service status:"
sudo systemctl status webcam-streamer --no-pager -n 20

echo ""
echo "To view live logs: sudo journalctl -u webcam-streamer -f"
