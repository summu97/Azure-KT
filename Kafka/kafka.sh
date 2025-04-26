sudo vim multi-broker-kafka.sh
-------------------
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
BROKER_COUNT=${BROKER_COUNT:-3}  # Default to 3 brokers if not set

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
for i in $(seq 1 $BROKER_COUNT); do
    DIR="${STORAGE_BASE}/broker$i"
    sudo mkdir -p "$DIR"
    sudo chown -R kafka:kafka "$DIR"
done
sudo chmod o+x /home/adqdevops2_gmail_com

echo "📜 Creating configs for each broker..."
for i in $(seq 1 $BROKER_COUNT); do
    PORT=$((9090 + i*2))          # 9092, 9094, 9096, ...
    CTRL_PORT=$((9091 + i*2))     # 9093, 9095, 9097, ...
    LOG_DIR="${STORAGE_BASE}/broker$i"
    CONF_DIR="$INSTALL_DIR/config/kraft$i"
    sudo mkdir -p "$CONF_DIR"

    # Correctly create the controller quorum voters
    VOTERS=""
    for j in $(seq 1 $BROKER_COUNT); do
        PEER_CTRL_PORT=$((9091 + j*2))
        if [ -n "$VOTERS" ]; then
            VOTERS="${VOTERS},${j}@${HOST_IP}:${PEER_CTRL_PORT}"
        else
            VOTERS="${j}@${HOST_IP}:${PEER_CTRL_PORT}"
        fi
    done

    sudo tee "$CONF_DIR/server.properties" > /dev/null <<EOF
process.roles=broker,controller
node.id=$i
controller.quorum.voters=$VOTERS
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
done

echo "🔐 Formatting broker 1 to generate cluster ID..."
CLUSTER_ID=$($INSTALL_DIR/bin/kafka-storage.sh random-uuid)
sudo -u kafka $INSTALL_DIR/bin/kafka-storage.sh format -t "$CLUSTER_ID" -c "$INSTALL_DIR/config/kraft1/server.properties"

echo "🔁 Copying cluster ID to other brokers..."
for i in $(seq 2 $BROKER_COUNT); do
    CONF_DIR="$INSTALL_DIR/config/kraft$i"
    LOG_DIR="${STORAGE_BASE}/broker$i"
    sudo rm -f "$LOG_DIR/meta.properties"
    sudo -u kafka $INSTALL_DIR/bin/kafka-storage.sh format -t "$CLUSTER_ID" -c "$CONF_DIR/server.properties"
done

echo "🛠️ Creating systemd services..."
for i in $(seq 1 $BROKER_COUNT); do
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

# Start broker 1 first and ensure it's running
sudo systemctl enable kafka-broker1
sudo systemctl start kafka-broker1
echo "⏳ Waiting for Broker 1 to start..."
sleep 10  # Give Broker 1 time to initialize

# Start the rest of the brokers after Broker 1 is running
for i in $(seq 2 $BROKER_COUNT); do
    sudo systemctl enable kafka-broker$i
    sudo systemctl start kafka-broker$i
done

echo "✅ Kafka with $BROKER_COUNT brokers is now running on a single node!"
echo ""
echo "🧪 Broker Ports:"
for i in $(seq 1 $BROKER_COUNT); do
    PORT=$((9090 + i*2))
    echo "  Broker $i: PLAINTEXT://${HOST_IP}:${PORT}"
done
echo ""
echo "🔍 To check broker status:"
for i in $(seq 1 $BROKER_COUNT); do
    echo "  sudo systemctl status kafka-broker$i"
done

-------------------
sudo chmod +x multi-broker-kafka.sh
-------------------
BROKER_COUNT=3 ./multi-broker-kafka.sh
-------------------
sudo systemctl status kafka-broker1
-------------------
source ~/.bashrc

kafka-topics.sh --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --topic first-topic --create
-------------------
🔍 View logs for each broker:
sudo journalctl -u kafka-broker1 -f
-------------------
Broker 1 — nodeId=1 on port 9092

Broker 2 — nodeId=2 on port 9094

Broker 3 — nodeId=3 on port 9096,
-------------------
sudo rm -rf storage
sudo rm -rf /opt/kafka
========================================================================================================================================
