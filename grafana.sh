#!/bin/bash

set -xe  # Enable debug mode and Exit on any error
LOG_FILE="/var/log/grafana_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect stdout and stderr to log file

# Define version and URLs
GRAFANA_VERSION="11.5.1"
GRAFANA_DEB="grafana_${GRAFANA_VERSION}_amd64.deb"
GRAFANA_URL="https://dl.grafana.com/oss/release/${GRAFANA_DEB}"
GRAFANA_USER="grafana"

echo "Starting Grafana installation..."

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y adduser libfontconfig1 musl

# Ensure Grafana user exists
if ! id "$GRAFANA_USER" &>/dev/null; then
    sudo adduser --system --no-create-home --group "$GRAFANA_USER"
    echo "User $GRAFANA_USER created."
else
    echo "User $GRAFANA_USER already exists."
fi

# Download Grafana package
echo "Downloading Grafana..."
curl -LO "$GRAFANA_URL"

# Verify download (Optional: Add checksum verification if available)
if [ -f "$GRAFANA_DEB" ]; then
    echo "Download successful: $GRAFANA_DEB"
else
    echo "Error: Failed to download Grafana package."
    exit 1
fi

# Install Grafana
echo "Installing Grafana..."
sudo dpkg -i "$GRAFANA_DEB"

# Reload systemd and start Grafana
echo "Starting Grafana service..."
sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server

# Verify service status
echo "Checking Grafana service status..."
sudo systemctl status grafana-server --no-pager

# Cleanup
echo "Cleaning up..."
rm -f "$GRAFANA_DEB"

echo "Grafana installation completed successfully."
echo "Access Grafana at: http://<your-server-ip>:3000"
echo "Default config at: /etc/grafana/grafana.ini"
set +x  # Disable debug mode
