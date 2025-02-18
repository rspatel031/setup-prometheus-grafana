#!/bin/bash

set -xe  # Enable debug mode and Exit on any error
set -o pipefail  # Catch errors in piped commands

LOG_FILE="/var/log/prometheus_server_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect stdout and stderr to log file

PROMETHEUS_VERSION="3.2.0"
PROMETHEUS_USER="prometheus"
PROMETHEUS_GROUP="prometheus"
PROMETHEUS_DIR="/etc/prometheus"
PROMETHEUS_LIB_DIR="/var/lib/prometheus"
PROMETHEUS_BIN_DIR="/usr/local/bin"
PROMETHEUS_SERVICE="/etc/systemd/system/prometheus.service"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
PROMETHEUS_TAR="prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"

echo "🚀 Starting Prometheus installation..."

# Create prometheus user if not exists
if ! id "$PROMETHEUS_USER" &>/dev/null; then
    echo "👤 Creating Prometheus user..."
    sudo useradd --no-create-home --shell /bin/false "$PROMETHEUS_USER"
else
    echo "✅ Prometheus user already exists."
fi

# Create required directories
echo "📂 Creating directories..."
sudo mkdir -p "$PROMETHEUS_DIR" "$PROMETHEUS_LIB_DIR"

# Set correct permissions
echo "🔑 Setting permissions..."
sudo chown -R "$PROMETHEUS_USER":"$PROMETHEUS_GROUP" "$PROMETHEUS_DIR" "$PROMETHEUS_LIB_DIR"

# Download Prometheus
if [ ! -f "$PROMETHEUS_TAR" ]; then
    echo "⬇️ Downloading Prometheus v$PROMETHEUS_VERSION..."
    wget -q "$PROMETHEUS_URL"
else
    echo "✅ Prometheus archive already downloaded."
fi

# Extract and install
echo "📦 Extracting Prometheus..."
tar -xvf "$PROMETHEUS_TAR" >/dev/null
cd "prometheus-${PROMETHEUS_VERSION}.linux-amd64" || exit

echo "🚀 Moving Prometheus binaries to $PROMETHEUS_BIN_DIR..."
sudo mv prometheus promtool "$PROMETHEUS_BIN_DIR"
sudo chown "$PROMETHEUS_USER":"$PROMETHEUS_GROUP" "$PROMETHEUS_BIN_DIR"/prometheus "$PROMETHEUS_BIN_DIR"/promtool

# Move config file if not exists
if [ ! -f "$PROMETHEUS_DIR/prometheus.yml" ]; then
    echo "📄 Moving Prometheus config..."
    sudo mv prometheus.yml "$PROMETHEUS_DIR/"
    sudo chown "$PROMETHEUS_USER":"$PROMETHEUS_GROUP" "$PROMETHEUS_DIR/prometheus.yml"
else
    echo "✅ Prometheus config already exists."
fi

# Create systemd service file
echo "⚙️ Creating Prometheus systemd service..."
cat <<EOF | sudo tee "$PROMETHEUS_SERVICE" >/dev/null
[Unit]
Description=Prometheus Monitoring System
Wants=network-online.target
After=network-online.target

[Service]
User=$PROMETHEUS_USER
Group=$PROMETHEUS_GROUP
Type=simple
ExecStart=$PROMETHEUS_BIN_DIR/prometheus \\
    --config.file=$PROMETHEUS_DIR/prometheus.yml \\
    --storage.tsdb.path=$PROMETHEUS_LIB_DIR \\
    --web.listen-address=0.0.0.0:9090

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Prometheus
echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl restart prometheus

# Check status
echo "🔍 Checking Prometheus status..."
sudo systemctl status prometheus --no-pager

echo "✅ Prometheus installation completed!"
echo "🌐 Open the following URL in your browser:"
echo "👉 http://<server-ip>:9090"
set +x  # Disable debug mode
