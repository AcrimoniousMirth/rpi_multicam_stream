#!/bin/bash
# Helper script to check what's using the camera streaming ports

echo "Checking ports used by webcam streamer..."
echo ""
echo "Port 8081:"
sudo lsof -i :8081 || echo "  Port 8081 is free"
echo ""
echo "Port 8082:"
sudo lsof -i :8082 || echo "  Port 8082 is free"
echo ""
echo "To kill processes on a port, use:"
echo "  sudo kill -9 <PID>"
