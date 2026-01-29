# MTKC POC - Terraform Outputs
# @author Shanaka Jayasundera - shanakaj@gmail.com

output "resource_group_name" {
  description = "Resource Group name"
  value       = module.resource_group.name
}

output "aks_cluster_name" {
  description = "AKS Cluster name"
  value       = module.aks.cluster_name
}

output "aks_get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.cluster_name}"
}

output "appgw_name" {
  description = "Application Gateway name"
  value       = module.app_gateway.name
}

output "appgw_public_ip" {
  description = "Application Gateway Public IP"
  value       = module.app_gateway.public_ip_address
}

output "app_urls_https" {
  description = "HTTPS URLs for applications"
  value = var.enable_https ? {
    health = "https://${module.app_gateway.public_ip_address}/healthz/ready"
    app1   = "https://${module.app_gateway.public_ip_address}/app1"
    app2   = "https://${module.app_gateway.public_ip_address}/app2"
  } : null
}

output "app_urls_http" {
  description = "HTTP URLs for applications (redirects to HTTPS when enabled)"
  value = {
    health = "http://${module.app_gateway.public_ip_address}/healthz/ready"
    app1   = "http://${module.app_gateway.public_ip_address}/app1"
    app2   = "http://${module.app_gateway.public_ip_address}/app2"
  }
}

output "https_enabled" {
  description = "Whether HTTPS is enabled"
  value       = var.enable_https
}

output "appgw_backend_pool_name" {
  description = "Backend pool name to update with Internal LB IP"
  value       = module.app_gateway.backend_pool_name
}

output "update_backend_pool_command" {
  description = "Command to update backend pool (replace <INTERNAL_LB_IP>)"
  value       = "az network application-gateway address-pool update --resource-group ${module.resource_group.name} --gateway-name ${module.app_gateway.name} --name ${module.app_gateway.backend_pool_name} --servers <INTERNAL_LB_IP>"
}

# Module-specific outputs
output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.network.vnet_id
}

output "aks_subnet_id" {
  description = "AKS Subnet ID"
  value       = module.network.aks_subnet_id
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL for workload identity"
  value       = module.aks.oidc_issuer_url
}

# ArgoCD Outputs
output "argocd_enabled" {
  description = "Whether ArgoCD is enabled"
  value       = var.enable_argocd
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = var.enable_argocd ? module.argocd[0].namespace : null
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = var.enable_argocd ? module.argocd[0].admin_password : null
  sensitive   = true
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = var.enable_argocd ? module.argocd[0].server_url : null
}

output "argocd_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = var.enable_argocd ? module.argocd[0].port_forward_command : "ArgoCD not enabled. Set enable_argocd = true"
}

# Azure API Management Outputs
output "apim_enabled" {
  description = "Whether Azure APIM is enabled"
  value       = var.enable_apim
}

output "apim_name" {
  description = "Azure APIM instance name"
  value       = var.enable_apim ? module.apim[0].apim_name : null
}

output "apim_gateway_url" {
  description = "Azure APIM Gateway URL"
  value       = var.enable_apim ? module.apim[0].apim_gateway_url : null
}

output "apim_private_ip" {
  description = "Azure APIM Private IP (when VNet integrated)"
  value       = var.enable_apim ? module.apim[0].apim_private_ip_addresses : null
}

output "apim_portal_url" {
  description = "Azure APIM Developer Portal URL"
  value       = var.enable_apim ? module.apim[0].apim_portal_url : null
}

# Note: API configurations (APIs, operations, policies) are now managed by
# Azure Service Operator (ASO) via ArgoCD for GitOps pattern.
# See: kubernetes/10-apim-api-config.yaml

# =============================================================================
# Azure Front Door + Blob Storage Outputs
# =============================================================================

output "front_door_enabled" {
  description = "Whether Azure Front Door is enabled"
  value       = var.enable_front_door
}

output "front_door_endpoint_url" {
  description = "Azure Front Door endpoint URL"
  value       = var.enable_front_door ? module.front_door[0].endpoint_url : null
}

output "front_door_static_assets_url" {
  description = "URL for static assets via Front Door"
  value       = var.enable_front_door ? module.front_door[0].static_assets_url : null
}

output "front_door_sku" {
  description = "Azure Front Door SKU"
  value       = var.enable_front_door ? module.front_door[0].sku_name : null
}

output "front_door_id" {
  description = "Unique Front Door ID (X-Azure-FDID header value) for validating traffic origin"
  value       = var.enable_front_door ? module.front_door[0].front_door_id : null
}

output "front_door_restriction_enabled" {
  description = "Whether App Gateway and APIM are restricted to Front Door traffic only"
  value       = var.enable_front_door && var.restrict_to_front_door
}

output "static_assets_storage_account" {
  description = "Storage account name for static assets"
  value       = var.enable_front_door ? module.static_assets[0].storage_account_name : null
}

output "static_assets_direct_url" {
  description = "Direct URL for static assets (Blob Storage)"
  value       = var.enable_front_door ? module.static_assets[0].static_assets_base_url : null
}

output "front_door_urls" {
  description = "URLs for accessing applications via Front Door"
  value = var.enable_front_door ? {
    home        = module.front_door[0].endpoint_url
    demo        = "${module.front_door[0].endpoint_url}/demo"
    app1        = "${module.front_door[0].endpoint_url}/app1"
    app2        = "${module.front_door[0].endpoint_url}/app2"
    static_css  = "${module.front_door[0].endpoint_url}/static/css/styles.css"
    static_logo = "${module.front_door[0].endpoint_url}/static/images/logo.svg"
  } : null
}

# Recommended access patterns
output "recommended_urls" {
  description = "Recommended URLs for different traffic types"
  value = {
    web_traffic = var.enable_front_door ? "Via Front Door: ${module.front_door[0].endpoint_url}" : "Via App Gateway: https://${module.app_gateway.public_ip_address}"
    api_traffic = var.enable_apim ? "Via APIM directly: ${module.apim[0].apim_gateway_url}" : "API not enabled"
    static_assets = var.enable_front_door ? "Via Front Door: ${module.front_door[0].static_assets_url}" : "Front Door not enabled"
  }
}
