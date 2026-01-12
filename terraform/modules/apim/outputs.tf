# Azure API Management Module - Outputs
# @author Shanaka Jayasundera - shanakaj@gmail.com

output "apim_id" {
  description = "APIM instance ID"
  value       = azurerm_api_management.main.id
}

output "apim_name" {
  description = "APIM instance name"
  value       = azurerm_api_management.main.name
}

output "apim_gateway_url" {
  description = "APIM Gateway URL"
  value       = azurerm_api_management.main.gateway_url
}

output "apim_gateway_regional_url" {
  description = "APIM Gateway Regional URL"
  value       = azurerm_api_management.main.gateway_regional_url
}

output "apim_management_api_url" {
  description = "APIM Management API URL"
  value       = azurerm_api_management.main.management_api_url
}

output "apim_portal_url" {
  description = "APIM Developer Portal URL"
  value       = azurerm_api_management.main.developer_portal_url
}

output "apim_private_ip_addresses" {
  description = "APIM Private IP addresses (when VNet integrated)"
  value       = azurerm_api_management.main.private_ip_addresses
}

output "apim_public_ip_addresses" {
  description = "APIM Public IP addresses"
  value       = azurerm_api_management.main.public_ip_addresses
}

# Note: API configurations are now managed by ASO via ArgoCD
# See: kubernetes/10-apim-api-config.yaml
