output "server" {
    value = azurerm_container_registry.acr.login_server
}

output "docker_login" {
  value = "docker login ${azurerm_container_registry.acr.login_server} -u ${azurerm_azuread_service_principal.acr-sp.application_id} -p ${azurerm_azuread_service_principal_password.acr-sp-pass.value}"
}

output "kubernetes_secret" {
  value = "kubectl create secret docker-registry docker-rep-pull --docker-server=${azurerm_container_registry.acr.login_server} --docker-username='${azurerm_azuread_service_principal.acr-sp.application_id}' --docker-password='${azurerm_azuread_service_principal_password.acr-sp-pass.value}'"
}

output "username" {
    value = azurerm_azuread_service_principal.acr-sp.application_id
}

output "password" {
    value = azurerm_azuread_service_principal_password.acr-sp-pass.value
}
