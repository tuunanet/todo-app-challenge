variable "location" {
  description = "Azure location to deploy resources"
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "todo-rg"
}

variable "cosmos_account_name" {
  description = "Cosmos DB account name (unique)"
  type        = string
  default     = "todocosmosacct"
}

variable "static_site_name" {
  description = "Static Web App name"
  type        = string
  default     = "todo-static-site"
}
