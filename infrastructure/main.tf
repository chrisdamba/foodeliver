terraform {
  required_version = ">=1.0"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

data "aws_availability_zones" "available" {
  filter {
    name   = "group-name"
    values = [var.region]
  }
}

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

locals {
  az_names = sort(data.aws_availability_zones.available.names)
}

locals {
  kafka_topics = [
    "order_placed_events",
    "order_preparation_events",
    "order_ready_events",
    "delivery_partner_assignment_events",
    "order_pickup_events",
    "partner_location_events",
    "order_in_transit_events",
    "delivery_status_check_events",
    "order_delivery_events",
    "order_cancellation_events",
    "user_behaviour_events",
    "restaurant_status_events",
    "review_events",
  ]
}

resource "confluent_environment" "development" {
  display_name = "Development"

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_kafka_cluster" "foodatasim_cluster" {
  display_name = "foodatasim-cluster-${random_id.cluster_id.hex}"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.region
  basic {}

  environment {
    id = confluent_environment.development.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "random_id" "cluster_id" {
  byte_length = 4
}

resource "random_id" "foodatasim_node_id" {
  byte_length = 2
  keepers = {
    key_name = var.key_name
  }
}
resource "confluent_service_account" "foodatasim-sa" {
  display_name = "foodatasim-app-sa"
  description  = "Service Account for foodatasim app"
}

resource "confluent_role_binding" "foodatasim-sa-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.foodatasim-sa.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.foodatasim_cluster.rbac_crn
}


resource "confluent_api_key" "foodatasim-sa-kafka-api-key" {
  display_name = "foodatasim-sa-kafka-api-key"
  description  = "Kafka API Key that is owned by 'foodatasim-sa' service account"
  owner {
    id          = confluent_service_account.foodatasim-sa.id
    api_version = confluent_service_account.foodatasim-sa.api_version
    kind        = confluent_service_account.foodatasim-sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.foodatasim_cluster.id
    api_version = confluent_kafka_cluster.foodatasim_cluster.api_version
    kind        = confluent_kafka_cluster.foodatasim_cluster.kind

    environment {
      id = confluent_environment.development.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    confluent_role_binding.foodatasim-sa-kafka-cluster-admin
  ]
}

resource "confluent_kafka_topic" "foodatasim_topics" {
  for_each        = toset(local.kafka_topics)
  topic_name            = each.key
  kafka_cluster {
    id = confluent_kafka_cluster.foodatasim_cluster.id
  }
  partitions_count   = 4
  rest_endpoint      = confluent_kafka_cluster.foodatasim_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.foodatasim-sa-kafka-api-key.id
    secret = confluent_api_key.foodatasim-sa-kafka-api-key.secret
  }
  config = {
    "cleanup.policy"                      = "delete"
    "delete.retention.ms"                 = "86400000"
    "max.compaction.lag.ms"               = "9223372036854775807"
    "max.message.bytes"                   = "2097164"
    "message.timestamp.after.max.ms"      = "9223372036854775807"
    "message.timestamp.before.max.ms"     = "9223372036854775807"      
    "message.timestamp.difference.max.ms" = "9223372036854775807"
    "message.timestamp.type"              = "CreateTime"
    "min.compaction.lag.ms"               = "0"
    "min.insync.replicas"                 = "2"
    "retention.bytes"                     = "-1"
    "retention.ms"                        = "604800000"
    "segment.bytes"                       = "104857600"
    "segment.ms"                          = "604800000"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_key_pair" "deployer_kp" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Create a new VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr

  tags = {
    Name = "MainVPC"
  }
}

# Create Public Subnets
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainIGW"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for foodatasim
resource "aws_security_group" "foodatasim_sg" {
  name        = "foodatasim_sg"
  description = "Allow SSH and outbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [join("/", [var.my_ip, "32"])]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "foodatasim_sg"
  }
}

resource "confluent_network" "aws-peering" {
  display_name     = "AWS Peering Network"
  cloud            = "AWS"
  region           = var.region
  cidr             = var.vpc_cidr
  connection_types = ["PEERING"]
  environment {
    id = confluent_environment.development.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

# EC2 Instance for foodatasim
resource "aws_instance" "foodatasim" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.foodatasim_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = true
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt install apt-transport-https ca-certificates curl software-properties-common -y",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \\\"$VERSION_CODENAME\\\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo docker run -d --name foodatasim \\",
      "  -e FOODATASIM_KAFKA_ENABLED=true \\",
      "  -e FOODATASIM_KAFKA_USE_LOCAL=false \\",
      "  -e FOODATASIM_KAFKA_BROKER_LIST=\"${var.confluent_bootstrap_servers}\" \\",
      "  -e FOODATASIM_KAFKA_SECURITY_PROTOCOL=\"SASL_SSL\" \\",
      "  -e FOODATASIM_KAFKA_SASL_MECHANISM=\"PLAIN\" \\",
      "  -e FOODATASIM_KAFKA_SASL_USERNAME=\"${var.confluent_cloud_api_key}\" \\",
      "  -e FOODATASIM_KAFKA_SASL_PASSWORD=\"${var.confluent_cloud_api_secret}\" \\",
      "  ${var.foodatasim_docker_image}"
    ]
  }

  tags = {
    Name = "foodatasim_node-${random_id.foodatasim_node_id.dec}"
  }
}
