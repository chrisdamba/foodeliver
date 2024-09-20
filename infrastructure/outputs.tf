output "kafka_private_ip" {
  value = aws_instance.kafka.private_ip
}

output "foodatasim_public_ip" {
  value = aws_instance.foodatasim.public_ip
}
