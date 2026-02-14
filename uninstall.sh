#!/bin/bash

# USB Webcam Streamer Uninstallation Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration - use current user's home directory
INSTALL_DIR="${HOME}/webcam-streamer"
SERVICE_NAME="webcam-streamer.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

# Allow override via environment variable
if [ -n "${WEBCAM_INSTALL_DIR}" ]; then
    INSTALL_DIR="${WEBCAM_INSTALL_DIR}"
fi

echo -e "${YELLOW}USB Webcam Streamer - Uninstallation${NC}"
echo "===================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run this script as root/sudo${NC}"
    echo "The script will ask for sudo password when needed"
    exit 1
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall the webcam streamer? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled"
    exit 0
fi

# Stop service
if sudo systemctl is-active --quiet ${SERVICE_NAME}; then
    echo -e "${GREEN}Stopping service...${NC}"
    sudo systemctl stop ${SERVICE_NAME}
fi

# Disable service
if sudo systemctl is-enabled --quiet ${SERVICE_NAME} 2>/dev/null; then
    echo -e "${GREEN}Disabling service...${NC}"
    sudo systemctl disable ${SERVICE_NAME}
fi

# Remove service file
if [ -f "${SERVICE_FILE}" ]; then
    echo -e "${GREEN}Removing service file...${NC}"
    sudo rm "${SERVICE_FILE}"
    sudo systemctl daemon-reload
fi

# Ask about removing installation directory
echo ""
read -p "Remove installation directory (${INSTALL_DIR})? This will delete your config! (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "${INSTALL_DIR}" ]; then
        echo -e "${GREEN}Removing installation directory...${NC}"
        rm -rf "${INSTALL_DIR}"
    fi
else
    echo -e "${YELLOW}Keeping installation directory${NC}"
fi

echo ""
echo -e "${GREEN}Uninstallation complete!${NC}"
