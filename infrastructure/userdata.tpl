#!/bin/bash
set -ex

# Update server package index
sudo apt update -y

# Install all required dependency packages
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y


# Add the Docker GPG key to your server's keyring
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

# Add the latest Docker repository to your APT sources.
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update server package index again
sudo apt update -y

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker and enable it on boot
sudo systemctl start docker
sudo systemctl enable docker

# Add the 'ubuntu' user to the 'docker' group
usermod -aG docker ubuntu

# Pull and run foodatasim Docker image
sudo docker pull ${foodatasim_docker_image}

# Pull and run foodatasim Docker image
sudo -u ubuntu docker run -d \
  --name foodatasim \
  -e KAFKA_BROKER_LIST="${kafka_private_ip}:9092" \
  ${foodatasim_docker_image}
