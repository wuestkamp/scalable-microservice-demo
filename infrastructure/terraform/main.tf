provider "azurerm" {
    version = "~>1.32"
}

module "azure-k8s-cluster" {
  source = "./modules/azure-k8s-cluster"
  client_id = var.azure_client_id
  client_secret = var.azure_client_secret
}

module "azure-container-registry" {
  source = "./modules/azure-container-registry"
}

module "azure-cosmos-db" {
  source = "./modules/azure-cosmos-db"
}

module "ccloud-kafka-cluster" {
  source = "./modules/ccloud-kafka-cluster"
  cluster_name = "scalable_microservice_cluster"
  cluster_cloud_provider = "aws"
  environment_name = "scalable_microservice_env"
}
