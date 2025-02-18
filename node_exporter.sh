#!/bin/bash

set -xe  # Enable debug mode and Exit on any error
set -o pipefail  # Ensure errors in piped commands are caught
LOG_FILE="/var/log/node_exporter_install.log"
exec > >(tee -a "$LOG_FILE") 2>&1  # Redirect stdout and stderr to log file

NODE_EXPORTER_VERSION="1.9.0"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_GROUP="node_exporter"
NODE_EXPORTER_DIR="/var/lib/node_exporter"
NODE_EXPORTER_BIN="/usr/local/bin/node_exporter"
TEXTFILE_COLLECTOR_DIR="$NODE_EXPORTER_DIR/textfile_collector"
NODE_EXPORTER_SERVICE="/etc/systemd/system/node_exporter.service"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
NODE_EXPORTER_TAR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "🚀 Starting Node Exporter installation..."

# Create node_exporter user if not exists
if ! id "$NODE_EXPORTER_USER" &>/dev/null; then
    echo "👤 Creating Node Exporter user..."
    sudo useradd --no-create-home --shell /bin/false "$NODE_EXPORTER_USER"
else
    echo "✅ Node Exporter user already exists."
fi

# Download Node Exporter
if [ ! -f "$NODE_EXPORTER_TAR" ]; then
    echo "⬇️ Downloading Node Exporter v$NODE_EXPORTER_VERSION..."
    wget -q "$NODE_EXPORTER_URL"
else
    echo "✅ Node Exporter archive already downloaded."
fi

# Extract and install
echo "📦 Extracting Node Exporter..."
tar -xvf "$NODE_EXPORTER_TAR" >/dev/null
cd "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64" || exit

echo "🚀 Moving Node Exporter binary to $NODE_EXPORTER_BIN..."
sudo mv node_exporter "$NODE_EXPORTER_BIN"
sudo chown "$NODE_EXPORTER_USER":"$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_BIN"

# Create directories for textfile collector
echo "📂 Creating directories for textfile collector..."
sudo mkdir -p "$TEXTFILE_COLLECTOR_DIR"
sudo chown -R "$NODE_EXPORTER_USER":"$NODE_EXPORTER_GROUP" "$NODE_EXPORTER_DIR"
sudo chmod -R 755 "$NODE_EXPORTER_DIR"

# Create systemd service file
echo "⚙️ Creating Node Exporter systemd service..."
cat <<EOF | sudo tee "$NODE_EXPORTER_SERVICE" >/dev/null
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_GROUP
Type=simple
ExecStart=$NODE_EXPORTER_BIN --collector.textfile.directory=$TEXTFILE_COLLECTOR_DIR

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Node Exporter
echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

# Check status
echo "🔍 Checking Node Exporter status..."
sudo systemctl status node_exporter --no-pager

echo "✅ Node Exporter installation completed!"
echo "🌐 Check metrics using:"
echo "👉 curl http://localhost:9100/metrics"
set +x  # Disable debug mode
