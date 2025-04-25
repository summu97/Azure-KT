
https://dlcdn.apache.org/kafka/3.8.1/kafka_2.12-3.8.1.tgz
https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_DIR}.tgz
------------------------
------------------------
sudo vim kafka.sh

#!/bin/bash

set -e

# === CONFIGURABLE ===
KAFKA_VERSION="3.8.1"
SCALA_VERSION="2.12"
KAFKA_DIR="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_URL="https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
INSTALL_DIR="/opt/kafka"
STORAGE_DIR="/home/adqdevops2_gmail_com/storage/broker1"  # Provide directory names for your broker
NODE_ID=1
HOST_IP=$(hostname -I | awk '{print $1}')  # Picks first IP

echo "🔧 Installing Java & dependencies..."
sudo apt update && sudo apt install -y openjdk-11-jdk wget

echo "👤 Creating 'kafka' user..."
sudo useradd -m -s /bin/bash kafka || echo "User 'kafka' already exists"

echo "📁 Downloading and setting up Kafka (KRaft mode)..."
cd /opt
sudo wget -q $KAFKA_URL
sudo tar -xzf "${KAFKA_DIR}.tgz"
sudo mv $KAFKA_DIR kafka
sudo chown -R kafka:kafka $INSTALL_DIR
sudo rm "${KAFKA_DIR}.tgz"

echo "📁 Preparing storage directory..."
sudo mkdir -p $STORAGE_DIR
sudo chown -R kafka:kafka "$(dirname "$STORAGE_DIR")"
sudo chmod o+x /home/adqdevops2_gmail_com  # Ensure 'kafka' user can traverse into home dir

echo "📜 Creating KRaft config..."
sudo mkdir -p $INSTALL_DIR/config/kraft
sudo tee $INSTALL_DIR/config/kraft/server.properties > /dev/null <<EOF
process.roles=broker,controller
node.id=${NODE_ID}
controller.quorum.voters=${NODE_ID}@${HOST_IP}:9093
listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
advertised.listeners=PLAINTEXT://${HOST_IP}:9092
controller.listener.names=CONTROLLER
log.dirs=${STORAGE_DIR}
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
group.initial.rebalance.delay.ms=0
EOF

echo "🔐 Formatting storage with cluster ID..."
sudo -u kafka $INSTALL_DIR/bin/kafka-storage.sh format -t $($INSTALL_DIR/bin/kafka-storage.sh random-uuid) -c $INSTALL_DIR/config/kraft/server.properties

echo "🛠️ Creating systemd service for Kafka in KRaft mode..."
sudo tee /etc/systemd/system/kafka.service > /dev/null <<EOF
[Unit]
Description=Apache Kafka (KRaft mode)
After=network.target

[Service]
Type=simple
User=kafka
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $INSTALL_DIR/config/kraft/server.properties
Restart=on-failure
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF

echo "🔁 Reloading and enabling Kafka service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable kafka

echo "🚀 Starting Kafka..."
sudo systemctl start kafka

echo "📦 Updating .bashrc for Kafka CLI tools..."
# grep -qxF "export PATH=$INSTALL_DIR/bin:\$PATH" ~/.bashrc || echo "export PATH=$INSTALL_DIR/bin:\$PATH" >> ~/.bashrc
echo "export PATH=${INSTALL_DIR}/bin:\$PATH" >> ~/.bashrc
# echo 'export PATH=/opt/kafka/bin:$PATH' >> ~/.bashrc


echo "✅ Kafka (KRaft mode) is now installed and running as a systemd service!"
echo ""
echo "🔍 To check Kafka status:"
echo "  sudo systemctl status kafka"
echo ""
echo "📦 Kafka is installed at: $INSTALL_DIR"
echo "🌐 Broker accessible at: PLAINTEXT://${HOST_IP}:9092"


sudo chmod +x kafka.sh

sh kafka.sh


source ~/.bashrc

kafka-topics.sh --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --topic first-topic --create
---------------------------=====================================================================================================
Under development:
🧠 Kafka node IDs and ports are hardcoded for simplicity, but you can customize them later.

#!/bin/bash

set -e

# === CONFIGURABLE ===
KAFKA_VERSION="3.8.1"
SCALA_VERSION="2.12"
KAFKA_DIR="kafka_${SCALA_VERSION}-${KAFKA_VERSION}"
KAFKA_URL="https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_DIR}.tgz"
INSTALL_DIR="/opt/kafka"
STORAGE_BASE="/home/adqdevops2_gmail_com/storage"
HOST_IP=$(hostname -I | awk '{print $1}')

echo "🔧 Installing Java & dependencies..."
sudo apt update && sudo apt install -y openjdk-11-jdk wget

echo "👤 Creating 'kafka' user..."
sudo useradd -m -s /bin/bash kafka || echo "User 'kafka' already exists"

echo "📁 Downloading and setting up Kafka (KRaft mode)..."
cd /opt
sudo wget -q $KAFKA_URL
sudo tar -xzf "${KAFKA_DIR}.tgz"
sudo mv $KAFKA_DIR kafka
sudo chown -R kafka:kafka $INSTALL_DIR
sudo rm "${KAFKA_DIR}.tgz"

echo "📁 Preparing storage directories..."
for i in 1 2 3; do
    DIR="${STORAGE_BASE}/broker$i"
    sudo mkdir -p "$DIR"
    sudo chown -R kafka:kafka "$DIR"
done
sudo chmod o+x /home/adqdevops2_gmail_com

echo "📜 Creating configs for each broker..."
for i in 1 2 3; do
    PORT=$((9090 + i*2))          # 9092, 9094, 9096
    CTRL_PORT=$((9091 + i*2))     # 9093, 9095, 9097
    LOG_DIR="${STORAGE_BASE}/broker$i"
    CONF_DIR="$INSTALL_DIR/config/kraft$i"
    sudo mkdir -p "$CONF_DIR"

    sudo tee "$CONF_DIR/server.properties" > /dev/null <<EOF
process.roles=broker,controller
node.id=$i
controller.quorum.voters=1@${HOST_IP}:9093,2@${HOST_IP}:9095,3@${HOST_IP}:9097
listeners=PLAINTEXT://0.0.0.0:${PORT},CONTROLLER://0.0.0.0:${CTRL_PORT}
advertised.listeners=PLAINTEXT://${HOST_IP}:${PORT}
controller.listener.names=CONTROLLER
log.dirs=${LOG_DIR}
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
group.initial.rebalance.delay.ms=0
EOF

    echo "🔐 Formatting broker $i..."
    sudo -u kafka $INSTALL_DIR/bin/kafka-storage.sh format -t "$($INSTALL_DIR/bin/kafka-storage.sh random-uuid)" -c "$CONF_DIR/server.properties"
done

echo "🛠️ Creating systemd services..."
for i in 1 2 3; do
    sudo tee /etc/systemd/system/kafka-broker$i.service > /dev/null <<EOF
[Unit]
Description=Apache Kafka Broker $i (KRaft mode)
After=network.target

[Service]
Type=simple
User=kafka
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $INSTALL_DIR/config/kraft$i/server.properties
Restart=on-failure
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF
done

echo "🔁 Reloading and enabling services..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
for i in 1 2 3; do
    sudo systemctl enable kafka-broker$i
    sudo systemctl start kafka-broker$i
done


echo "✅ Kafka with 3 brokers is now running on a single node!"
echo ""
echo "🧪 Broker Ports:"
echo "  Broker 1: PLAINTEXT://${HOST_IP}:9092"
echo "  Broker 2: PLAINTEXT://${HOST_IP}:9094"
echo "  Broker 3: PLAINTEXT://${HOST_IP}:9096"
echo ""
echo "🔍 To check broker status:"
echo "  sudo systemctl status kafka-broker1"
echo "  sudo systemctl status kafka-broker2"
echo "  sudo systemctl status kafka-broker3"
========================================================================================================================================
