#!/bin/bash
set -e

echo "STEP-1: Installing Git, OpenJDK 17, and Maven"
sudo apt-get update
sudo apt-get install -y git openjdk-17-jdk maven wget gnupg2

echo "Verify Java version"
java -version

echo "STEP-2: Adding Jenkins repo and importing GPG key"
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "STEP-3: Update packages and install Jenkins"
sudo apt-get update
sudo apt-get install -y jenkins

echo "STEP-4: Start and enable Jenkins service"
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins --no-pager

echo "All done! Jenkins should be up and running with Java 17 and Maven installed."
