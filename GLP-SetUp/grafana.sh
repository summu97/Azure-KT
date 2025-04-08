#!/bin/bash

set -e

# Install the prerequisite packages (auto-approve)
sudo apt-get update -y
sudo apt-get install -y apt-transport-https software-properties-common wget gnupg

# Import the GPG key (no prompt)
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

# Add Grafana APT repository (no prompt)
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Update packages list (auto-approve)
sudo apt-get update -y

# Install Grafana OSS latest version (auto-approve)
sudo apt-get install -y grafana

# Enable and start Grafana service
sudo systemctl enable --now grafana-server

# Confirm Grafana status
sudo systemctl status grafana-server --no-pager

### USEFUL
# sudo /bin/systemctl daemon-reload
# sudo /bin/systemctl enable grafana-server
# sudo /bin/systemctl start grafana-server
