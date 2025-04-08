#!/bin/bash

set -e

echo "🛑 Stopping Node Exporter service..."
sudo systemctl stop node_exporter || echo "Service not running."

echo "❌ Disabling Node Exporter service..."
sudo systemctl disable node_exporter || echo "Service not enabled."

echo "🧹 Removing Node Exporter systemd service file..."
sudo rm -f /etc/systemd/system/node_exporter.service

echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

echo "🚮 Removing Node Exporter binary..."
sudo rm -f /usr/local/bin/node_exporter

echo "👤 Deleting 'node_exporter' user..."
sudo userdel -r node_exporter 2>/dev/null || echo "User 'node_exporter' not found or already deleted."

echo "✅ Node Exporter has been uninstalled successfully."
