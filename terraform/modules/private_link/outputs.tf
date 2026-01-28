# Private Link Module Outputs
# @author Shanaka Jayasundera - shanakaj@gmail.com

output "private_link_subnet_id" {
  description = "Private Link subnet ID"
  value       = azurerm_subnet.private_link.id
}

output "internal_lb_pls_id" {
  description = "Private Link Service ID for Internal LB"
  value       = var.enable_internal_lb_pls ? azurerm_private_link_service.internal_lb[0].id : null
}

output "internal_lb_pls_alias" {
  description = "Private Link Service alias for Internal LB (used by Front Door)"
  value       = var.enable_internal_lb_pls ? azurerm_private_link_service.internal_lb[0].alias : null
}

output "apim_private_endpoint_ip" {
  description = "Private IP address of APIM Private Endpoint"
  value       = var.enable_apim_private_endpoint ? azurerm_private_endpoint.apim[0].private_service_connection[0].private_ip_address : null
}

output "apim_private_endpoint_id" {
  description = "Private Endpoint ID for APIM"
  value       = var.enable_apim_private_endpoint ? azurerm_private_endpoint.apim[0].id : null
}
