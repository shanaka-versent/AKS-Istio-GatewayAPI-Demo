# MTKC POC - Terraform Variables
# @author Shanaka Jayasundera - shanakaj@gmail.com

# Azure Subscription
variable "subscription_id" {
  description = "Azure Subscription ID (optional - uses az CLI default if not set)"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiaeast"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "poc"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mtkc"
}

# Network
variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_cidr" {
  description = "AKS subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "appgw_subnet_cidr" {
  description = "App Gateway subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "network_policy" {
  description = "Network policy provider (azure, calico, cilium)"
  type        = string
  default     = "azure"
}

# AKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32.5"
}

variable "aks_sku_tier" {
  description = "AKS SKU tier (Free, Standard, Premium)"
  type        = string
  default     = "Free"
}

variable "aks_node_count" {
  description = "Number of AKS system nodes"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for AKS system nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

# User Node Pool (optional)
variable "enable_user_node_pool" {
  description = "Enable separate user node pool"
  type        = bool
  default     = false
}

variable "user_node_count" {
  description = "Number of user nodes"
  type        = number
  default     = 2
}

variable "user_node_vm_size" {
  description = "VM size for user nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

# AKS Autoscaling
variable "enable_aks_autoscaling" {
  description = "Enable AKS cluster autoscaler"
  type        = bool
  default     = false
}

variable "system_node_min_count" {
  description = "Minimum number of system nodes (when autoscaling enabled)"
  type        = number
  default     = 1
}

variable "system_node_max_count" {
  description = "Maximum number of system nodes (when autoscaling enabled)"
  type        = number
  default     = 3
}

variable "user_node_min_count" {
  description = "Minimum number of user nodes (when autoscaling enabled)"
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "Maximum number of user nodes (when autoscaling enabled)"
  type        = number
  default     = 5
}

# AKS Monitoring
variable "enable_monitoring" {
  description = "Enable Log Analytics monitoring for AKS"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

# AKS Security
variable "enable_azure_policy" {
  description = "Enable Azure Policy addon for AKS"
  type        = bool
  default     = false
}

variable "enable_rg_role_assignment" {
  description = "Enable Network Contributor role on resource group for kubelet"
  type        = bool
  default     = false
}

# TLS Configuration
variable "enable_https" {
  description = "Enable HTTPS on App Gateway"
  type        = bool
  default     = true
}

variable "appgw_ssl_cert_path" {
  description = "Path to App Gateway SSL certificate (PFX format)"
  type        = string
  default     = "../certs/appgw.pfx"
}

variable "appgw_ssl_cert_password" {
  description = "Password for App Gateway SSL certificate"
  type        = string
  sensitive   = true
  default     = "MTKCPoc2024!"
}

variable "backend_https_enabled" {
  description = "Enable HTTPS for backend (Istio Gateway)"
  type        = bool
  default     = true
}

# App Gateway Autoscaling
variable "enable_appgw_autoscaling" {
  description = "Enable autoscaling for App Gateway"
  type        = bool
  default     = false
}

variable "appgw_min_capacity" {
  description = "Minimum App Gateway capacity (when autoscaling enabled)"
  type        = number
  default     = 1
}

variable "appgw_max_capacity" {
  description = "Maximum App Gateway capacity (when autoscaling enabled)"
  type        = number
  default     = 3
}

# App Gateway Features
variable "enable_rewrite_rules" {
  description = "Enable rewrite rules for client headers (X-Forwarded-For, X-Real-IP, etc.)"
  type        = bool
  default     = false
}

# ArgoCD Configuration
variable "enable_argocd" {
  description = "Enable ArgoCD deployment via Terraform"
  type        = bool
  default     = false
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.55.0"
}

variable "argocd_enable_ha" {
  description = "Enable ArgoCD High Availability mode"
  type        = bool
  default     = false
}

# Azure API Management Configuration
variable "enable_apim" {
  description = "Enable Azure API Management deployment"
  type        = bool
  default     = false
}

variable "apim_subnet_cidr" {
  description = "APIM subnet CIDR"
  type        = string
  default     = "10.0.3.0/24"
}

variable "apim_publisher_name" {
  description = "APIM publisher name (organization name)"
  type        = string
  default     = "MTKC POC"
}

variable "apim_publisher_email" {
  description = "APIM publisher email"
  type        = string
  default     = "admin@example.com"
}

variable "apim_sku_name" {
  description = "APIM SKU (Developer_1, Basic_1, Standard_1, Premium_1)"
  type        = string
  default     = "Developer_1"
  # Developer_1: ~$50/month, good for POC
  # Basic_1: ~$150/month
  # Standard_1: ~$700/month
  # Premium_1: ~$3000/month (VNet integration)
}

variable "apim_virtual_network_type" {
  description = "APIM VNet integration type (None, External, Internal)"
  type        = string
  default     = "External"
  # Internal: Only accessible within VNet
  # External: Has public IP but can access VNet resources
  # None: No VNet integration
}

# Note: API configurations (APIs, operations, policies) are now managed by
# Azure Service Operator (ASO) via ArgoCD for GitOps pattern.
# See: kubernetes/10-apim-api-config.yaml

# =============================================================================
# Azure Front Door + Blob Storage (CDN Caching)
# Similar to AWS CloudFront + S3 pattern
# =============================================================================

variable "enable_front_door" {
  description = "Enable Azure Front Door for CDN caching"
  type        = bool
  default     = false
}

variable "front_door_sku" {
  description = "Front Door SKU (Standard_AzureFrontDoor or Premium_AzureFrontDoor). Premium required for private APIM integration."
  type        = string
  default     = "Standard_AzureFrontDoor"
  # Standard: ~$35/month + traffic costs
  # Premium: ~$330/month + traffic costs (required for Private Link to APIM)
}

variable "upload_sample_static_assets" {
  description = "Upload sample static assets (CSS, JS, images) to Blob Storage"
  type        = bool
  default     = true
}

variable "enable_front_door_waf" {
  description = "Enable WAF policy on Front Door"
  type        = bool
  default     = false
}

variable "front_door_waf_mode" {
  description = "WAF mode: Detection or Prevention"
  type        = string
  default     = "Detection"
}

# Tags
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Project   = "MTKC-POC"
    Purpose   = "Gateway-API-AppGW-Integration"
    ManagedBy = "Terraform"
  }
}
