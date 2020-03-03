# azure k8s cluster
output "azure-k8s-cluster_client_key" {
    value = module.azure-k8s-cluster.client_key
}
output "azure-k8s-cluster_client_certificate" {
    value = module.azure-k8s-cluster.client_certificate
}
output "azure-k8s-cluster_cluster_ca_certificate" {
    value = module.azure-k8s-cluster.cluster_ca_certificate
}
output "azure-k8s-cluster_cluster_username" {
    value = module.azure-k8s-cluster.cluster_username
}
output "azure-k8s-cluster_cluster_password" {
    value = module.azure-k8s-cluster.cluster_password
}
output "azure-k8s-cluster_kube_config" {
    value = module.azure-k8s-cluster.kube_config
}
output "azure-k8s-cluster_host" {
    value = module.azure-k8s-cluster.host
}


# azure cosmos db
output "azure-cosmos_db-endpoint" {
    value = module.azure-cosmos-db.endpoint
}
output "azure-cosmos_db-connection_strings" {
    value = module.azure-cosmos-db.connection_strings
}
output "azure-cosmos_db-connection_string_one" {
    value = module.azure-cosmos-db.connection_strings[0]
}


# azure container registry
output "azure-container-registry-login_server" {
    value = module.azure-container-registry.server
}
output "azure-container-registry-docker_login" {
    value = module.azure-container-registry.docker_login
}
output "azure-container-registry-kubernetes_secret" {
    value = module.azure-container-registry.kubernetes_secret
}
output "azure-container-registry-username" {
    value = module.azure-container-registry.username
}
output "azure-container-registry-password" {
    value = module.azure-container-registry.password
}


# kafka
output "ccloud-kafka-cluster_kafka_url" {
  value = module.ccloud-kafka-cluster.kafka_url
}
output "ccloud-kafka-cluster_key" {
  value = module.ccloud-kafka-cluster.key
}
output "ccloud-kafka-cluster_secret" {
  value = module.ccloud-kafka-cluster.secret
}
