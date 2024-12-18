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

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Setting up $SERVICE_NAME..."

# Step 1: Create target directories
echo "Creating necessary directories..."
mkdir -p "$INSTALL_DIR" "$LOG_DIR" "$DATA_DIR" "$CONFIG_DIR"

# Step 2: Copy the Python script to the target installation directory
echo "Copying Python script to $INSTALL_DIR..."
cp "$SCRIPT_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Step 3: Create the configuration file
echo "Creating configuration file at $CONFIG_FILE..."
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat <<EOF > "$CONFIG_FILE"
{
    "sleep_interval": 3600
}
EOF
    echo "Default configuration written to $CONFIG_FILE."
else
    echo "Configuration file already exists. Skipping creation."
fi

# Step 4: Set up log rotation for the log directory
LOGROTATE_FILE="/etc/logrotate.d/$SERVICE_NAME"
echo "Setting up log rotation..."
cat <<EOF > "$LOGROTATE_FILE"
$LOG_DIR/*.log {
    size 5M
    rotate 5
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
EOF

# Step 5: Set permissions for directories
echo "Setting permissions..."
chown -R root:root "$INSTALL_DIR" "$LOG_DIR" "$DATA_DIR" "$CONFIG_DIR"
chmod -R 750 "$INSTALL_DIR" "$DATA_DIR"
chmod -R 755 "$CONFIG_DIR" "$LOG_DIR"

# Step 6: Create the systemd service file
echo "Creating systemd service file at $SERVICE_FILE..."
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Pi-hole Elasticsearch Sync Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 $INSTALL_DIR/$SCRIPT_NAME
WorkingDirectory=$INSTALL_DIR
User=root
Group=root
Restart=always
Environment=PYTHONUNBUFFERED=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Reload systemd and enable the service
echo "Reloading systemd and enabling $SERVICE_NAME service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"

# Step 8: Start the service
echo "Starting $SERVICE_NAME service..."
systemctl start "$SERVICE_NAME"

# Step 9: Display status
echo "Service $SERVICE_NAME installation complete."
systemctl status "$SERVICE_NAME"
