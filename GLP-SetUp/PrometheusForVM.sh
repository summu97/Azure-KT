#!/bin/bash

set -e

# Define version
PROM_VERSION="2.52.0"

# Update system packages
echo "Updating packages..."
sudo apt-get update -y

# Create prometheus user if not exists
if ! id "prometheus" &>/dev/null; then
  sudo useradd --system --no-create-home --shell /bin/false prometheus
  echo "Created prometheus user."
else
  echo "User prometheus already exists."
fi

# Download and extract Prometheus
echo "Downloading Prometheus..."
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz   

echo "Extracting Prometheus..."
tar -xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64/

# Create necessary directories
echo "Creating directories..."
sudo mkdir -p /data /etc/prometheus

# Move binaries
echo "Moving binaries..."
sudo mv prometheus promtool /usr/local/bin/

# Move console templates and config
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

# Set ownership
echo "Setting permissions..."
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/

# Create Prometheus systemd service
echo "Creating systemd service file..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/data \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries \\
  --web.listen-address=0.0.0.0:9090 \\
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF'

sudo cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'Jenkins_exporter_metrics'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
EOF


# Reload systemd and start service
echo "Starting Prometheus service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Check status
echo "Checking Prometheus status..."
sudo systemctl status prometheus --no-pager
