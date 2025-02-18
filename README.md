# Prometheus, Node Exporter, Alertmanager, and Grafana Installation

This repository provides shell scripts to install and configure Prometheus, Node Exporter, Alertmanager, and Grafana on a Linux-based system.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
    - [Prometheus](#prometheus)
    - [Node Exporter](#node-exporter)
    - [Alertmanager](#alertmanager)
    - [Grafana](#grafana)
- [Service Management](#service-management)
- [Accessing the Web Interfaces](#accessing-the-web-interfaces)
- [Logging](#logging)

## Prerequisites
Ensure your system meets the following requirements:
- A Linux-based system (Ubuntu, Debian, CentOS, etc.)
- Internet connectivity to download packages
- `wget` and `curl` installed
- `systemd` for service management
- Root or sudo privileges

## Installation
The following sections describe how to install each component.

### Prometheus
Prometheus is a monitoring system and time-series database.

#### Steps:
1. Run the installation script:

   ```bash
   chmod +x prometheus.sh
   sudo ./prometheus.sh
   ```

2. The script performs the following:
    - Creates a dedicated Prometheus user
    - Downloads and installs Prometheus binaries
    - Configures Prometheus systemd service
    - Starts and enables the Prometheus service

### Node Exporter
Node Exporter is used to collect system metrics.

#### Steps:
1. Run the installation script:
   
   ```bash
   chmod +x node_exporter.sh
   sudo ./node_exporter.sh
   ```

2. The script performs the following:
    - Creates a dedicated Node Exporter user
    - Downloads and installs Node Exporter
    - Configures Node Exporter systemd service
    - Starts and enables the Node Exporter service

### Alertmanager
Alertmanager handles alerts from Prometheus.

#### Steps:
1. Run the installation script:
   
   ```bash
   chmod +x alert_manager.sh
   sudo ./alert_manager.sh
   ```

2. The script performs the following:
    - Creates a dedicated Alertmanager user
    - Downloads and installs Alertmanager binaries
    - Configures Alertmanager systemd service
    - Starts and enables the Alertmanager service

### Grafana
Grafana is used to visualize Prometheus metrics.

#### Steps:
1. Run the installation script:
   
   ```bash
   chmod +x grafana.sh
   sudo ./grafana.sh
   ```

2. The script performs the following:
    - Downloads and installs Grafana
    - Configures Grafana systemd service
    - Starts and enables the Grafana service

## Service Management
Use the following commands to manage the services:

### Start a service:
```bash
sudo systemctl start <service-name>
```

### Stop a service:
```bash
sudo systemctl stop <service-name>
```

### Restart a service:
```bash
sudo systemctl restart <service-name>
```

### Check service status:
```bash
sudo systemctl status <service-name>
```

Replace `<service-name>` with `prometheus`, `node_exporter`, `alertmanager`, or `grafana-server` as needed.

## Prometheus Configuration
Prometheus is configured to scrape metrics from Node Exporter. Below is the `/etc/prometheus/prometheus.yml` configuration to enable node scraping:

```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
```

## Accessing the Web Interfaces
- **Prometheus UI**: `http://<server-ip>:9090`
- **Node Exporter Metrics**: `http://<server-ip>:9100/metrics`
- **Alertmanager UI**: `http://<server-ip>:9093`
- **Grafana UI**: `http://<server-ip>:3000`
    - Default credentials: `admin/admin`

## Logging
Logs for each component are stored in:
- Prometheus: `/var/log/prometheus_install.log`
- Node Exporter: `/var/log/node_exporter_install.log`
- Alertmanager: `/var/log/alert_manager_install.log`
- Grafana: `/var/log/grafana_install.log`


## Notes
- Ensure that your firewall allows required ports (9090, 9100, 9093, 3000).
- Modify `/etc/prometheus/prometheus.yml` as needed to include additional scrape targets.

🚀 Happy Monitoring!
