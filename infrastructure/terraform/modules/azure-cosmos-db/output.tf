output "endpoint" {
    value = azurerm_cosmosdb_account.db.endpoint
}

output "connection_strings" {
    value = azurerm_cosmosdb_account.db.connection_strings
}
