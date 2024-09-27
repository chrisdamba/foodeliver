resource "aws_kms_key" "foodatasim_kms_key" {
  description             = "KMS key 1"
  deletion_window_in_days = 10
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