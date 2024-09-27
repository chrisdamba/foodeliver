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