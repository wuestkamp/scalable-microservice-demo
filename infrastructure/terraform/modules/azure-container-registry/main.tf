resource "azurerm_resource_group" "scalable_microservice" {
    name     = var.resource_group_name
    location = var.resource_group_location
}

//resource "azurerm_container_registry" "acr" {
//  name                     = "containerRregistryScalableMicroservice"
//  resource_group_name      = azurerm_resource_group.scalable_microservice.name
//  location                 = azurerm_resource_group.scalable_microservice.location
//  sku                      = "Standard"
//  admin_enabled            = true
//  network_rule_set         = []
//}

resource "azurerm_container_registry" "acr" {
  name                = "containerRregistryScalableMicroservice"
  resource_group_name = azurerm_resource_group.scalable_microservice.name
  location            = azurerm_resource_group.scalable_microservice.location
  sku                 = "standard"
}

resource "azurerm_azuread_application" "acr-app" {
  name = "acr-app"
}

resource "azurerm_azuread_service_principal" "acr-sp" {
  application_id = azurerm_azuread_application.acr-app.application_id
}

resource "azurerm_azuread_service_principal_password" "acr-sp-pass" {
  service_principal_id = azurerm_azuread_service_principal.acr-sp.id
  value                = "Password666"
  end_date             = "2030-01-01T01:02:03Z"
}

resource "azurerm_role_assignment" "acr-assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_azuread_service_principal_password.acr-sp-pass.service_principal_id
}
