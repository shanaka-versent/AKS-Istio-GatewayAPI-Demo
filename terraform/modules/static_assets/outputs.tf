# Static Assets Module Outputs

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.static_assets.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.static_assets.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.static_assets.primary_blob_endpoint
}

output "primary_web_endpoint" {
  description = "Primary static website endpoint URL"
  value       = azurerm_storage_account.static_assets.primary_web_endpoint
}

output "primary_web_host" {
  description = "Primary static website host (without https://)"
  value       = azurerm_storage_account.static_assets.primary_web_host
}

output "container_name" {
  description = "Name of the static assets container"
  value       = azurerm_storage_container.static.name
}

output "static_assets_base_url" {
  description = "Base URL for static assets"
  value       = "${azurerm_storage_account.static_assets.primary_blob_endpoint}${azurerm_storage_container.static.name}"
}
