resource "azurerm_resource_group" "scalable_microservice" {
    name     = var.resource_group_name
    location = var.resource_group_location
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "scalable-microservice-demo-${random_integer.ri.result}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    prefix            = "scalable-microservice-demo-${random_integer.ri.result}-customid"
    location          = var.resource_group_location
    failover_priority = 0
  }
}
