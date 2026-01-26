# Front Door Module Outputs

output "profile_id" {
  description = "ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "profile_name" {
  description = "Name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "endpoint_id" {
  description = "ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.id
}

output "endpoint_host_name" {
  description = "Host name of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "endpoint_url" {
  description = "Full URL of the Front Door endpoint"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

output "static_assets_url" {
  description = "URL for static assets via Front Door"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}/static"
}

output "web_url" {
  description = "URL for web traffic via Front Door"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

output "api_url" {
  description = "URL for API traffic via Front Door"
  value       = var.enable_apim_origin ? "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}/api" : "APIM origin not enabled"
}

output "waf_policy_id" {
  description = "ID of the WAF policy (if enabled)"
  value       = var.enable_waf ? azurerm_cdn_frontdoor_firewall_policy.main[0].id : null
}

output "sku_name" {
  description = "SKU of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.main.sku_name
}
