resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Cosmos DB account (MongoDB API)
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_account_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  enable_free_tier    = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongo_db" {
  name                = "todo-db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_mongo_collection" "todo_collection" {
  name                = "todos"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_mongo_database.mongo_db.name
  throughput          = 400
}

# Storage account for Function App (placeholder)
resource "azurerm_storage_account" "sa" {
  name                     = lower(substr(var.resource_group_name, 0, 11))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# App Service plan and Function App (Linux consumption or placeholder)
# Implementers should fill in additional settings and deployment workflow.
resource "azurerm_app_service_plan" "asp" {
  name                = "todo-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "function" {
  name                       = "todo-function-app"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_connection_string  = azurerm_storage_account.sa.primary_connection_string
  version                    = "~4"
  site_config {
    linux_fx_version = "Python|3.10"
  }

  # Recommended: set environment variables for COSMOS_MONGO_CONN etc.
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "COSMOS_MONGO_CONN" = "REPLACE_WITH_COSMOS_MONGO_CONNECTION_STRING"
  }
}

# Static Web App resource (placeholder). Depending on provider version, use the azurerm_static_site resource.
# The following is a minimal placeholder; when you plan to deploy, check the azurerm provider docs for exact fields.
resource "azurerm_static_site" "static" {
  name                = var.static_site_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Free"
  # branch, repository_url and build properties should be configured during CI/CD or manually
}
