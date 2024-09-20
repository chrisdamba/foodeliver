terraform {
  required_version = ">=1.0"
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
  }
}

provider "aws" {
  region = var.region
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

resource "random_id" "kafka_node_id" {
  byte_length = 2
  keepers = {
    key_name = var.key_name
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
}


# Security Group for Kafka
resource "aws_security_group" "kafka_sg" {
  name        = "kafka_sg"
  description = "Allow Kafka traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] 
  }

ingress {
    description = "Kafka External listener"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka JMX"
    from_port   = 9101
    to_port     = 9101
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Schema Registry API"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka REST Proxy"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka Connect REST API"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Instance for Kafka
resource "aws_instance" "kafka" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.large"
  subnet_id              = aws_subnet.public_subnets[1].id
  vpc_security_group_ids = [aws_security_group.kafka_sg.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = templatefile("${path.root}/kafkadata.tpl", {})

  tags = {
    Name = "kafka_node-${random_id.kafka_node_id.dec}"
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
  
  user_data = templatefile("${path.root}/userdata.tpl", {
    kafka_private_ip = aws_instance.kafka.private_ip
    foodatasim_docker_image     = var.foodatasim_docker_image
  })

  tags = {
    Name = "foodatasim_node-${random_id.kafka_node_id.dec}"
  }
}
