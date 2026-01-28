# Front Door Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region (used for tags, Front Door is global)"
  type        = string
}

variable "sku_name" {
  description = "SKU for Front Door. Standard_AzureFrontDoor or Premium_AzureFrontDoor"
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "SKU must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "blob_storage_host" {
  description = "Hostname for Blob Storage (static assets)"
  type        = string
}

variable "app_gateway_host" {
  description = "Hostname or IP for App Gateway (web traffic)"
  type        = string
}

variable "apim_host" {
  description = "Hostname for APIM (API traffic)"
  type        = string
  default     = ""
}

variable "enable_apim_origin" {
  description = "Enable APIM as Front Door origin. Recommended for: global/multi-region deployments, unified WAF policy, L7 DDoS protection. Not needed for: single region, cost-conscious deployments where APIM policies suffice."
  type        = bool
  default     = false # Enable for global/multi-region deployments
}

# =============================================================================
# Private Link Configuration (Premium SKU only)
# =============================================================================

variable "enable_private_link" {
  description = "Enable Private Link for origins (requires Premium SKU)"
  type        = bool
  default     = false
}

variable "private_link_target_type" {
  description = "Type of Private Link target: 'internal_lb' for AKS Internal LB, 'apim' for APIM"
  type        = string
  default     = "internal_lb"
}

# Internal LB Private Link
variable "internal_lb_pls_id" {
  description = "Private Link Service ID for Internal Load Balancer"
  type        = string
  default     = ""
}

variable "internal_lb_private_ip" {
  description = "Private IP of Internal Load Balancer"
  type        = string
  default     = ""
}

# APIM Private Link
variable "apim_private_link_enabled" {
  description = "Enable Private Link for APIM origin"
  type        = bool
  default     = false
}

variable "apim_id" {
  description = "APIM resource ID (for Private Link)"
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Whether to enable WAF policy"
  type        = bool
  default     = false
}

variable "waf_mode" {
  description = "WAF mode: Detection or Prevention"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be Detection or Prevention."
  }
}

variable "origin_verification_header" {
  description = "Custom header value for origin verification"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
