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
      "  -e FOODATASIM_KAFKA_SASL_USERNAME=\"${confluent_api_key.foodatasim-sa-kafka-api-key.id}\" \\",
      "  -e FOODATASIM_KAFKA_SASL_PASSWORD=\"${confluent_api_key.foodatasim-sa-kafka-api-key.secret}\" \\",
      "  -e FOODATASIM_SESSION_TIMEOUT_MS=45000 \\",
      "  ${var.foodatasim_docker_image}"
    ]
  }

  tags = {
    Name = "foodatasim_node-${random_id.foodatasim_node_id.dec}"
  }

  depends_on = [
    confluent_kafka_topic.foodatasim_topics,
    confluent_api_key.foodatasim-sa-kafka-api-key
  ]
}