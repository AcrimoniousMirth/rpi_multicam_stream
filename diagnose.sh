#!/bin/bash

# Diagnostic Script for Camera Streaming Issues
# Collects logs, checks cameras, network, and system resources

echo "======================================================================"
echo "Webcam Streamer Diagnostics"
echo "======================================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Service Status
echo -e "${BLUE}[1] Service Status${NC}"
echo "----------------------------------------------------------------------"
systemctl is-active webcam-streamer &>/dev/null
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓ Service is running${NC}"
else
    echo -e "  ${RED}✗ Service is NOT running${NC}"
fi
echo ""

# 2. Recent Logs (last 50 lines)
echo -e "${BLUE}[2] Recent Logs (last 50 lines)${NC}"
echo "----------------------------------------------------------------------"
sudo journalctl -u webcam-streamer -n 50 --no-pager | tail -20
echo "  ... (showing last 20 lines)"
echo ""

# 3. Camera Devices
echo -e "${BLUE}[3] Camera Devices${NC}"
echo "----------------------------------------------------------------------"
for device in /dev/video*; do
    if [ -c "$device" ]; then
        name=$(v4l2-ctl --device=$device --info 2>/dev/null | grep "Card type" | cut -d':' -f2 | xargs || echo "Unknown")
        in_use=$(lsof "$device" 2>/dev/null | grep -v COMMAND | wc -l)
        
        if [ "$in_use" -gt 0 ]; then
            echo -e "  ${GREEN}✓ $device - $name (IN USE)${NC}"
        else
            echo -e "  ${YELLOW}○ $device - $name (available)${NC}"
        fi
    fi
done
echo ""

# 4. Network Ports
echo -e "${BLUE}[4] Network Ports${NC}"
echo "----------------------------------------------------------------------"
for port in 8081 8082 8083 8084; do
    if sudo lsof -i :$port &>/dev/null; then
        process=$(sudo lsof -i :$port | grep LISTEN | awk '{print $1}' | head -n1)
        echo -e "  ${GREEN}✓ Port $port: LISTENING ($process)${NC}"
    else
        echo -e "  ${RED}✗ Port $port: NOT LISTENING${NC}"
    fi
done
echo ""

# 5. Network Accessibility
echo -e "${BLUE}[5] Network Configuration${NC}"
echo "----------------------------------------------------------------------"
ip_addr=$(hostname -I | awk '{print $1}')
echo "  Local IP: $ip_addr"
echo ""
echo "  Stream URLs (from other devices):"
echo "    http://$ip_addr:8081/stream"
echo "    http://$ip_addr:8082/stream"
echo ""

# Check firewall
if command -v ufw &>/dev/null; then
    if sudo ufw status | grep -q "inactive"; then
        echo -e "  ${GREEN}✓ Firewall (ufw): inactive${NC}"
    else
        echo -e "  ${YELLOW}○ Firewall (ufw): active${NC}"
        echo "    Check if ports 8081, 8082 are allowed:"
        sudo ufw status | grep -E "808[1-4]" || echo "    No rules found for ports 8081-8084"
    fi
else
    echo "  ○ Firewall: ufw not installed"
fi
echo ""

# 6. System Resources
echo -e "${BLUE}[6] System Resources${NC}"
echo "----------------------------------------------------------------------"

# CPU
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)
cpu_used=$(echo "100 - $cpu_idle" | bc 2>/dev/null || echo "N/A")
echo "  CPU Usage: ${cpu_used}%"

# Memory
mem_info=$(free -m | grep Mem:)
mem_total=$(echo $mem_info | awk '{print $2}')
mem_used=$(echo $mem_info | awk '{print $3}')
mem_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)
echo "  Memory: ${mem_used}MB / ${mem_total}MB (${mem_percent}%)"

# Temperature (if available)
if command -v vcgencmd &>/dev/null; then
    temp=$(vcgencmd measure_temp | cut -d'=' -f2)
    echo "  Temperature: $temp"
fi
echo ""

# 7. Active ffmpeg Processes
echo -e "${BLUE}[7] Active ffmpeg Processes${NC}"
echo "----------------------------------------------------------------------"
ffmpeg_count=$(pgrep -c ffmpeg || echo "0")
if [ "$ffmpeg_count" -gt 0 ]; then
    echo -e "  ${GREEN}✓ Found $ffmpeg_count ffmpeg process(es)${NC}"
    ps aux | grep ffmpeg | grep -v grep | while read line; do
        pid=$(echo $line | awk '{print $2}')
        cpu=$(echo $line | awk '{print $3}')
        mem=$(echo $line | awk '{print $4}')
        device=$(echo $line | grep -o '/dev/video[0-9]*' | head -n1)
        echo "    PID $pid: CPU ${cpu}%, MEM ${mem}%, Device: $device"
    done
else
    echo -e "  ${RED}✗ No ffmpeg processes running!${NC}"
    echo "    This means cameras are not capturing video"
fi
echo ""

# 8. Config File
echo -e "${BLUE}[8] Current Configuration${NC}"
echo "----------------------------------------------------------------------"
if [ -f ~/webcam-streamer/config.yaml ]; then
    echo "  Config file: ~/webcam-streamer/config.yaml"
    echo ""
    cat ~/webcam-streamer/config.yaml | grep -A 10 "cameras:" | head -n 20
else
    echo -e "  ${RED}✗ Config file not found${NC}"
fi
echo ""

# 9. USB Bandwidth (if available)
echo -e "${BLUE}[9] USB Information${NC}"
echo "----------------------------------------------------------------------"
if command -v lsusb &>/dev/null; then
    echo "  USB Cameras:"
    lsusb | grep -i "camera\|video\|webcam" || echo "    No cameras found in lsusb"
else
    echo "  lsusb not available"
fi
echo ""

# Summary
echo -e "${BLUE}======================================================================"
echo "Diagnostic Summary"
echo -e "======================================================================${NC}"
echo ""

# Check for common issues
if [ "$ffmpeg_count" -eq 0 ]; then
    echo -e "${RED}Issue: No ffmpeg processes running${NC}"
    echo "  → Cameras are not being captured"
    echo "  → Check logs for errors: sudo journalctl -u webcam-streamer -n 100"
    echo ""
fi

if ! systemctl is-active webcam-streamer &>/dev/null; then
    echo -e "${RED}Issue: Service not running${NC}"
    echo "  → Start with: sudo systemctl start webcam-streamer"
    echo ""
fi

if ! sudo lsof -i :8081 &>/dev/null; then
    echo -e "${RED}Issue: No server on port 8081${NC}"
    echo "  → Check if camera_1 failed to start"
    echo "  → Check logs for port conflicts or errors"
    echo ""
fi

echo "For detailed logs: sudo journalctl -u webcam-streamer -f"
echo "To restart service: sudo systemctl restart webcam-streamer"
echo ""
