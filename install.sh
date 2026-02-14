#!/bin/bash

# USB Webcam Streamer Installation Script
# Run this script on your Raspberry Pi to install and configure the service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/home/pi/webcam-streamer"
SERVICE_NAME="webcam-streamer.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

echo -e "${GREEN}USB Webcam Streamer - Installation${NC}"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root/sudo${NC}"
    echo "The script will ask for sudo password when needed"
    exit 1
fi

# Check if we're on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    echo -e "${YELLOW}Warning: This doesn't appear to be a Raspberry Pi${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update package list
echo -e "${GREEN}Updating package list...${NC}"
sudo apt-get update

# Install system dependencies
echo -e "${GREEN}Installing system dependencies...${NC}"
sudo apt-get install -y ffmpeg python3 python3-pip python3-yaml

# Create installation directory
echo -e "${GREEN}Creating installation directory...${NC}"
mkdir -p "${INSTALL_DIR}"

# Copy files
echo -e "${GREEN}Copying application files...${NC}"
cp main.py "${INSTALL_DIR}/"
cp camera_streamer.py "${INSTALL_DIR}/"
cp requirements.txt "${INSTALL_DIR}/"

# Copy or create config file
if [ -f "${INSTALL_DIR}/config.yaml" ]; then
    echo -e "${YELLOW}Existing config.yaml found, keeping it${NC}"
else
    echo -e "${GREEN}Creating default config.yaml${NC}"
    cp config.yaml "${INSTALL_DIR}/"
fi

# Make scripts executable
chmod +x "${INSTALL_DIR}/main.py"

# Install Python dependencies
echo -e "${GREEN}Installing Python dependencies...${NC}"
pip3 install -r "${INSTALL_DIR}/requirements.txt" --user

# Setup systemd service
echo -e "${GREEN}Setting up systemd service...${NC}"

# Update service file with correct paths
sed "s|/home/pi/webcam-streamer|${INSTALL_DIR}|g" webcam-streamer.service > /tmp/${SERVICE_NAME}

# Copy service file
sudo cp /tmp/${SERVICE_NAME} "${SERVICE_FILE}"
sudo chmod 644 "${SERVICE_FILE}"

# Reload systemd
echo -e "${GREEN}Reloading systemd...${NC}"
sudo systemctl daemon-reload

# Enable service
echo -e "${GREEN}Enabling service to start at boot...${NC}"
sudo systemctl enable ${SERVICE_NAME}

# Start service
echo -e "${GREEN}Starting service...${NC}"
sudo systemctl start ${SERVICE_NAME}

# Wait a moment for service to start
sleep 2

# Check status
if sudo systemctl is-active --quiet ${SERVICE_NAME}; then
    echo ""
    echo -e "${GREEN}Installation successful!${NC}"
    echo ""
    echo "The webcam streamer is now running and will start automatically at boot."
    echo ""
    echo "Configuration file: ${INSTALL_DIR}/config.yaml"
    echo ""
    echo "Useful commands:"
    echo "  View status:   sudo systemctl status ${SERVICE_NAME}"
    echo "  View logs:     sudo journalctl -u ${SERVICE_NAME} -f"
    echo "  Restart:       sudo systemctl restart ${SERVICE_NAME}"
    echo "  Stop:          sudo systemctl stop ${SERVICE_NAME}"
    echo "  Edit config:   nano ${INSTALL_DIR}/config.yaml"
    echo "                 (then restart service)"
    echo ""
    echo "Access your camera streams at:"
    echo "  http://$(hostname -I | awk '{print $1}'):8081/stream (camera 1)"
    echo "  http://$(hostname -I | awk '{print $1}'):8082/stream (camera 2)"
    echo ""
else
    echo ""
    echo -e "${RED}Service failed to start${NC}"
    echo "Check logs with: sudo journalctl -u ${SERVICE_NAME} -n 50"
    exit 1
fi
