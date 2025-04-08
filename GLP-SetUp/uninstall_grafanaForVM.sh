#!/bin/bash

echo "🔄 Stopping Grafana service..."
sudo systemctl stop grafana-server
sudo systemctl disable grafana-server

echo "🗑️ Removing Grafana package..."
sudo apt-get remove --purge -y grafana
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "🧹 Deleting Grafana data and config (if exists)..."
sudo rm -rf /etc/grafana
sudo rm -rf /var/lib/grafana
sudo rm -rf /var/log/grafana

echo "📁 Cleaning up Grafana repo and GPG key..."
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -f /etc/apt/keyrings/grafana.gpg
sudo apt-get update

echo "✅ Grafana has been uninstalled completely."
