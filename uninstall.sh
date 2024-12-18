#!/bin/bash

# Define variables
SERVICE_NAME="pihole-elasticsearch"
SCRIPT_NAME="pihole_elasticsearch_service.py"
INSTALL_DIR="/opt/$SERVICE_NAME"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
LOG_DIR="/var/log/$SERVICE_NAME"
DATA_DIR="/var/lib/$SERVICE_NAME"
CONFIG_DIR="/etc/$SERVICE_NAME"
CONFIG_FILE="$CONFIG_DIR/config.json"
LOGROTATE_FILE="/etc/logrotate.d/$SERVICE_NAME"

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Uninstalling $SERVICE_NAME..."

# Step 1: Stop and disable the systemd service
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Stopping $SERVICE_NAME service..."
    systemctl stop "$SERVICE_NAME"
fi

echo "Disabling $SERVICE_NAME service..."
systemctl disable "$SERVICE_NAME"

# Step 2: Remove the systemd service file
if [[ -f "$SERVICE_FILE" ]]; then
    echo "Removing service file at $SERVICE_FILE..."
    rm -f "$SERVICE_FILE"
fi

# Step 3: Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Step 4: Remove the installation directory
if [[ -d "$INSTALL_DIR" ]]; then
    echo "Removing installation directory at $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
fi

# Step 5: Remove the log directory
if [[ -d "$LOG_DIR" ]]; then
    echo "Removing log directory at $LOG_DIR..."
    rm -rf "$LOG_DIR"
fi

# Step 6: Remove the data directory
if [[ -d "$DATA_DIR" ]]; then
    echo "Removing data directory at $DATA_DIR..."
    rm -rf "$DATA_DIR"
fi

# Step 7: Remove the configuration directory
if [[ -d "$CONFIG_DIR" ]]; then
    echo "Removing configuration directory at $CONFIG_DIR..."
    rm -rf "$CONFIG_DIR"
fi

# Step 8: Remove logrotate configuration
if [[ -f "$LOGROTATE_FILE" ]]; then
    echo "Removing logrotate configuration at $LOGROTATE_FILE..."
    rm -f "$LOGROTATE_FILE"
fi

# Final message
echo "$SERVICE_NAME has been successfully uninstalled."
