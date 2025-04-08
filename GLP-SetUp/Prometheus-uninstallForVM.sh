# Stop and Disable the Prometheus Service
sudo systemctl stop prometheus
sudo systemctl disable prometheus

# Remove the Service File
sudo rm /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload

# Delete Prometheus Files and Directories
sudo rm -rf /etc/prometheus
sudo rm -rf /data
sudo rm -f /usr/local/bin/prometheus
sudo rm -f /usr/local/bin/promtool

# Remove Prometheus User and Group
sudo userdel -r prometheus 2>/dev/null
sudo groupdel prometheus 2>/dev/null
