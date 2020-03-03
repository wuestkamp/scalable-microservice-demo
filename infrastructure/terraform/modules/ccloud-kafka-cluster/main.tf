variable "cluster_name" {}
variable "cluster_cloud_provider" {}
variable "environment_name" {}

provider "confluentcloud" {}

resource "confluentcloud_environment" "test" {
  name = var.environment_name
}

resource "confluentcloud_kafka_cluster" "test" {
  name             = var.cluster_name
  environment_id   = confluentcloud_environment.test.id
  service_provider = var.cluster_cloud_provider
  region           = "eu-west-1"
  availability     = "LOW"
}

resource "confluentcloud_api_key" "provider_test" {
  cluster_id = confluentcloud_kafka_cluster.test.id
  environment_id   = confluentcloud_environment.test.id
}

//provider "kafka" {
//  bootstrap_servers = [replace(confluentcloud_kafka_cluster.test.bootstrap_servers, "SASL_SSL://", "")]
//
//  tls_enabled    = true
//  sasl_username  = confluentcloud_api_key.provider_test.key
//  sasl_password  = confluentcloud_api_key.provider_test.secret
//  sasl_mechanism = "plain"
//}

//resource "kafka_topic" "user-create" {
//  name               = "user-create"
//  replication_factor = 3
//  partitions         = 6
//}

//resource "kafka_topic" "user-create-response" {
//  name               = "user-create-response"
//  replication_factor = 3
//  partitions         = 6
//}

output "kafka_url" {
  value = replace(confluentcloud_kafka_cluster.test.bootstrap_servers, "SASL_SSL://", "")
}

output "key" {
  value = confluentcloud_api_key.provider_test.key
}

output "secret" {
  value = confluentcloud_api_key.provider_test.secret
}
