#!/bin/bash
# Description: Configure containerized Kafka server for demo

# Get the instance's private IP address
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
kafka_private_ip=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

# Create SWAP space
fallocate -l 4G /swapfile 
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf


# Install Docker, Docker-compose
sudo apt -y update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common jq
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt -y update
sudo apt install -y docker-ce
sudo systemctl start docker
sudo systemctl status docker

sudo usermod -aG docker ubuntu

sudo curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
sudo docker compose version


# Spawn Kafka Containers
sudo mkdir /root/kafka
cd /root/kafka
sudo tee /root/kafka/docker-compose.yml &>/dev/null <<EOF
version: '3.9'

services:
  broker:
    image: confluentinc/cp-kafka:7.4.0
    container_name: broker
    hostname: broker
    restart: always
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:29092,CONTROLLER://0.0.0.0:29093,PLAINTEXT_HOST://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:29092,PLAINTEXT_HOST://${kafka_private_ip}:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: broker
      KAFKA_JMX_OPTS: -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=broker -Dcom.sun.management.jmxremote.rmi.port=9101
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@${kafka_private_ip}:29093
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      # KAFKA_LOG_DIRS: /tmp/kraft-combined-logs
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      # Replace CLUSTER_ID with a unique base64 UUID using "bin/kafka-storage.sh random-uuid" 
      # See https://docs.confluent.io/kafka/operations-tools/kafka-tools.html#kafka-storage-sh
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
    ports:
      - 9092:9092
      - 9101:9101
    volumes:
      - broker_logdir:/var/lib/kafka/data
    networks:
      - kafka-network

  schema-registry:
    image: confluentinc/cp-schema-registry:7.4.0
    container_name: schema-registry
    hostname: schema-registry
    restart: always
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: broker:29092
      SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
      SCHEMA_REGISTRY_KAFKASTORE_TOPIC: __schemas
    ports:
      - 8081:8081
    networks:
      - kafka-network
    depends_on:
      - broker

  rest-proxy:
    image: confluentinc/cp-kafka-rest:7.4.0
    container_name: rest-proxy
    hostname: rest-proxy
    restart: always
    environment:
      KAFKA_REST_HOST_NAME: rest-proxy
      KAFKA_REST_BOOTSTRAP_SERVERS: broker:29092
      KAFKA_REST_LISTENERS: http://0.0.0.0:8082
      KAFKA_REST_SCHEMA_REGISTRY_URL: http://schema-registry:8081
    ports:
      - 8082:8082
    networks:
      - kafka-network
    depends_on:
      - broker
      - schema-registry

  kafka-connect:
    image: confluentinc/cp-kafka-connect:7.4.0
    container_name: kafka-connect
    hostname: kafka-connect
    restart: always
    environment:
      CONNECT_BOOTSTRAP_SERVERS: broker:29092
      CONNECT_REST_ADVERTISED_HOST_NAME: kafka-connect
      CONNECT_GROUP_ID: kafka-connect
      CONNECT_CONFIG_STORAGE_TOPIC: __connect-config
      CONNECT_OFFSET_STORAGE_TOPIC: __connect-offsets
      CONNECT_STATUS_STORAGE_TOPIC: __connect-status
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_OFFSET_FLUSH_INTERVAL_MS: 10000
      CONNECT_KEY_CONVERTER: org.apache.kafka.connect.storage.StringConverter
      CONNECT_VALUE_CONVERTER: io.confluent.connect.avro.AvroConverter
      CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      # CLASSPATH required due to CC-2422
      CLASSPATH: /usr/share/java/monitoring-interceptors/monitoring-interceptors-7.4.0.jar
      CONNECT_PRODUCER_INTERCEPTOR_CLASSES: io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor
      CONNECT_CONSUMER_INTERCEPTOR_CLASSES: io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor
      CONNECT_PLUGIN_PATH: /usr/share/java,/usr/share/confluent-hub-components
      CONNECT_LOG4J_LOGGERS: org.apache.zookeeper=ERROR,org.I0Itec.zkclient=ERROR,org.reflections=ERROR
    command:
      - bash
      - -c
      - |
        confluent-hub install --no-prompt confluentinc/kafka-connect-s3:10.5.0
        confluent-hub install --no-prompt confluentinc/connect-transforms:1.4.3
        confluent-hub install --no-prompt debezium/debezium-connector-postgresql:2.2.1
        /etc/confluent/docker/run &
        sleep infinity
    ports:
      - 8083:8083
    networks:
      - kafka-network
    depends_on:
      - broker
      - schema-registry

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    restart: always
    environment:
      DYNAMIC_CONFIG_ENABLED: true
      KAFKA_CLUSTERS_0_NAME: kafka-cluster
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: broker:29092
      KAFKA_CLUSTERS_0_METRICS_PORT: 9101
      KAFKA_CLUSTERS_0_SCHEMAREGISTRY: http://schema-registry:8081
      KAFKA_CLUSTERS_0_KAFKACONNECT_0_NAME: kafka-connect-cluster
      KAFKA_CLUSTERS_0_KAFKACONNECT_0_ADDRESS: http://kafka-connect:8083
    ports:
      - 8080:8080
    volumes:
      - kafkaui_dir:/etc/kafkaui
    networks:
      - kafka-network
    depends_on:
      - broker
      - schema-registry
      - kafka-connect

networks:
  kafka-network:
    driver: bridge

volumes:
  broker_logdir:
  kafkaui_dir:

EOF

sudo docker-compose up -d

sudo touch /root/done.out