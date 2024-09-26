variable "region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
}

variable "my_ip" {
  description = "My IP address"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_name" {
  description = "AWS Key Pair name for SSH access"
}

variable "public_key_path" {
  description = "Path to the public key"  
}

variable "private_key_path" {
  description = "Path to the private key" 
  
}
variable "server_ami" {
  description = "AMI ID for the EC2 instance running foodatasim and kafka"
}

variable "foodatasim_docker_image" {
  description = "Docker image for foodatasim"
}

variable "confluent_cloud_api_key" {
  description = "API key for Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "API secret for Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_cluster_id" {
  description = "Confluent Cloud Cluster ID"
  type        = string
  sensitive   = true
}

variable "confluent_bootstrap_servers" {
  description = "Confluent Cloud Bootstrap Servers"
  type        = string
}
