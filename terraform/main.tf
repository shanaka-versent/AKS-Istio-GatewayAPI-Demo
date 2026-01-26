# MTKC POC - Main Terraform Configuration
# @author Shanaka Jayasundera - shanakaj@gmail.com

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource_group"

  name_prefix = local.name_prefix
  location    = var.location
  tags        = var.tags
}

# Network Module
module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_address_space  = var.vnet_address_space
  aks_subnet_cidr     = var.aks_subnet_cidr
  appgw_subnet_cidr   = var.appgw_subnet_cidr

  # APIM Subnet (optional)
  enable_apim_subnet = var.enable_apim
  apim_subnet_cidr   = var.apim_subnet_cidr

  tags = var.tags
}

# AKS Module
module "aks" {
  source = "./modules/aks"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier

  # System Node Pool
  system_node_count   = var.aks_node_count
  system_node_vm_size = var.aks_node_vm_size

  # User Node Pool (optional)
  enable_user_node_pool = var.enable_user_node_pool
  user_node_count       = var.user_node_count
  user_node_vm_size     = var.user_node_vm_size

  # Autoscaling (optional)
  enable_autoscaling    = var.enable_aks_autoscaling
  system_node_min_count = var.system_node_min_count
  system_node_max_count = var.system_node_max_count
  user_node_min_count   = var.user_node_min_count
  user_node_max_count   = var.user_node_max_count

  # Networking
  subnet_id      = module.network.aks_subnet_id
  vnet_id        = module.network.vnet_id
  network_policy = var.network_policy

  # Monitoring (optional)
  enable_monitoring  = var.enable_monitoring
  log_retention_days = var.log_retention_days

  # Identity & Security
  enable_azure_policy      = var.enable_azure_policy
  enable_rg_role_assignment = var.enable_rg_role_assignment

  tags = var.tags
}

# Application Gateway Module
module "app_gateway" {
  source = "./modules/app_gateway"

  name_prefix           = local.name_prefix
  location              = var.location
  resource_group_name   = module.resource_group.name
  subnet_id             = module.network.appgw_subnet_id

  # HTTPS/TLS
  enable_https          = var.enable_https
  ssl_cert_path         = var.appgw_ssl_cert_path
  ssl_cert_password     = var.appgw_ssl_cert_password
  backend_https_enabled = var.backend_https_enabled
  backend_ca_cert_path  = "${path.module}/../certs/ca.crt"

  # Autoscaling (optional)
  enable_autoscaling = var.enable_appgw_autoscaling
  min_capacity       = var.appgw_min_capacity
  max_capacity       = var.appgw_max_capacity

  # Rewrite Rules
  enable_rewrite_rules = var.enable_rewrite_rules

  tags = var.tags
}

# ArgoCD Module (optional)
module "argocd" {
  source = "./modules/argocd"
  count  = var.enable_argocd ? 1 : 0

  namespace     = "argocd"
  release_name  = "argocd"
  chart_version = var.argocd_chart_version
  service_type  = "LoadBalancer"
  internal_lb   = true  # Use Azure Internal LoadBalancer
  enable_ha     = var.argocd_enable_ha

  depends_on = [module.aks]
}

# Azure API Management Module (optional)
# Infrastructure only - API configs managed by ASO via ArgoCD
module "apim" {
  source = "./modules/apim"
  count  = var.enable_apim ? 1 : 0

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = module.resource_group.name

  # Publisher info
  publisher_name  = var.apim_publisher_name
  publisher_email = var.apim_publisher_email

  # SKU (Developer for POC, Standard/Premium for production)
  sku_name = var.apim_sku_name

  # VNet Integration
  virtual_network_type = var.apim_virtual_network_type
  subnet_id            = module.network.apim_subnet_id

  tags = var.tags

  depends_on = [module.network, module.aks]

  # Note: API configurations (APIs, operations, policies) are now managed by
  # Azure Service Operator (ASO) via ArgoCD for GitOps pattern.
  # See: kubernetes/10-apim-api-config.yaml
}

# =============================================================================
# Azure Front Door + Blob Storage for CDN Caching
# Similar to AWS CloudFront + S3 pattern
# =============================================================================

# Static Assets Storage (Blob Storage)
module "static_assets" {
  source = "./modules/static_assets"
  count  = var.enable_front_door ? 1 : 0

  name_prefix          = local.name_prefix
  suffix               = random_string.suffix.result
  location             = var.location
  resource_group_name  = module.resource_group.name
  upload_sample_assets = var.upload_sample_static_assets

  allowed_origins = var.enable_front_door ? [
    "https://${local.name_prefix}-endpoint.azurefd.net",
    "https://${module.app_gateway.public_ip}"
  ] : ["*"]

  tags = var.tags
}

# Azure Front Door (CDN + WAF)
# Routes:
#   /static/* -> Blob Storage (cached 1 year)
#   /app*, /demo, /* -> App Gateway (no cache)
#   /api/* -> APIM directly (NOT through Front Door - best practice)
module "front_door" {
  source = "./modules/front_door"
  count  = var.enable_front_door ? 1 : 0

  name_prefix         = local.name_prefix
  resource_group_name = module.resource_group.name
  location            = var.location

  # SKU: Standard for POC, Premium for private APIM integration
  sku_name = var.front_door_sku

  # Origins
  blob_storage_host = module.static_assets[0].primary_web_host
  app_gateway_host  = module.app_gateway.public_ip

  # APIM Origin (NOT recommended - APIM has built-in caching/WAF)
  enable_apim_origin = false  # Best practice: access APIM directly
  apim_host          = var.enable_apim ? module.apim[0].gateway_url : ""

  # WAF (optional)
  enable_waf = var.enable_front_door_waf
  waf_mode   = var.front_door_waf_mode

  tags = var.tags

  depends_on = [module.static_assets, module.app_gateway]
}
