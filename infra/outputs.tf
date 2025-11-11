output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "cosmos_account_name" {
  value = azurerm_cosmosdb_account.cosmos.name
}

output "function_app_name" {
  value = azurerm_function_app.function.name
}

output "static_site_name" {
  value = azurerm_static_site.static.name
}
