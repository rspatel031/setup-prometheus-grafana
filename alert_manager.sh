#!/bin/bash

set -xe  # Enable debug mode and Exit on any error
set -o pipefail  # Ensure errors in piped commands are caught
LOG_FILE="/var/log/alert_manager_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect stdout and stderr to log file

# Define version
ALERTMANAGER_VERSION="0.28.0"
ALERTMANAGER_USER="alert_manager"
ALERTMANAGER_GROUP="alert_manager"
ALERTMANAGER_URL="https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/alertmanager"
DATA_DIR="/var/lib/alertmanager"

echo "Starting Alertmanager installation..."

# Create Alertmanager user if not exists
if ! id "$ALERTMANAGER_USER" &>/dev/null; then
    sudo useradd --no-create-home --shell /bin/false "$ALERTMANAGER_USER"
    echo "User $ALERTMANAGER_USER created."
else
    echo "User $ALERTMANAGER_USER already exists."
fi

# Download Alertmanager
echo "Downloading Alertmanager..."
curl -LO "$ALERTMANAGER_URL"
TAR_FILE="alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"

# Extract files
echo "Extracting Alertmanager..."
tar -xzf "$TAR_FILE"

# Move binaries to installation directory
cd "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64"
sudo mv alertmanager amtool "$INSTALL_DIR"

# Create necessary directories
sudo mkdir -p "$CONFIG_DIR" "$DATA_DIR"

# Move config file (Ensure it exists in the extracted folder)
if [ -f "alertmanager.yml" ]; then
    sudo mv alertmanager.yml "$CONFIG_DIR/alertmanager.yml"
else
    echo "Warning: alertmanager.yml not found. You need to configure it manually."
fi

# Set permissions
sudo chown -R "$ALERTMANAGER_USER:$ALERTMANAGER_GROUP" "$CONFIG_DIR" "$DATA_DIR"
sudo chown "$ALERTMANAGER_USER:$ALERTMANAGER_GROUP" "$CONFIG_DIR/alertmanager.yml" "$INSTALL_DIR/alertmanager" "$INSTALL_DIR/amtool"

# Create systemd service file
echo "Configuring Alertmanager service..."
cat <<EOF | sudo tee /etc/systemd/system/alertmanager.service >/dev/null
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=$ALERTMANAGER_USER
Group=$ALERTMANAGER_GROUP
Type=simple
ExecStart=$INSTALL_DIR/alertmanager \
  --config.file=$CONFIG_DIR/alertmanager.yml \
  --storage.path=$DATA_DIR

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start Alertmanager service
echo "Starting Alertmanager service..."
sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager

# Verify service status
sudo systemctl status alertmanager --no-pager

echo "Alertmanager installation completed successfully."
echo "Access the UI at: http://<your-server-ip>:9093"
set +x  # Disable debug mode
