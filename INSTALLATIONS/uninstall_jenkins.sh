#!/bin/bash
set -e

echo "Stopping Jenkins service..."
sudo systemctl stop jenkins || true

echo "Disabling Jenkins service..."
sudo systemctl disable jenkins || true

echo "Removing Jenkins package and dependencies..."
sudo apt-get purge -y jenkins

echo "Removing Java 17, Git, Maven..."
sudo apt-get purge -y openjdk-17-jdk git maven

echo "Removing Jenkins repo and keyring..."
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /etc/apt/keyrings/jenkins-keyring.asc

echo "Cleaning up packages and dependencies no longer required..."
sudo apt-get autoremove -y
sudo apt-get clean

echo "Uninstall complete."
