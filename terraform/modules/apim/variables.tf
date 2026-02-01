# Azure API Management Module - Variables (Infrastructure Only)
# @author Shanaka Jayasundera - shanakaj@gmail.com
#
# Note: API configuration variables are no longer needed here.
# API configs are managed by ASO via ArgoCD (kubernetes/10-apim-api-config.yaml)

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "publisher_name" {
  description = "APIM publisher name"
  type        = string
}

variable "publisher_email" {
  description = "APIM publisher email"
  type        = string
}

variable "sku_name" {
  description = "APIM SKU (Developer, Basic, Standard, Premium)"
  type        = string
  default     = "Developer_1"
  # Developer_1 is cheapest for POC (~$50/month)
  # Production would use Standard_1 or Premium_1
}

variable "virtual_network_type" {
  description = "VNet integration type (None, External, Internal)"
  type        = string
  default     = "External"
  # Internal = APIM only accessible within VNet
  # External = APIM has public IP but can access VNet resources
}

variable "subnet_id" {
  description = "Subnet ID for APIM VNet integration"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Global Security Policy Variables
# =============================================================================
variable "enable_global_policy" {
  description = "Enable global security policies (rate limiting, CORS, security headers)"
  type        = bool
  default     = true
}

variable "rate_limit_calls" {
  description = "Maximum number of calls allowed per renewal period per IP"
  type        = number
  default     = 100
}

variable "rate_limit_period" {
  description = "Rate limit renewal period in seconds"
  type        = number
  default     = 60
}

variable "max_request_body_size" {
  description = "Maximum request body size in bytes (default 1MB)"
  type        = number
  default     = 1048576
}

variable "enable_cors" {
  description = "Enable CORS policy"
  type        = bool
  default     = false
}

variable "cors_allow_credentials" {
  description = "Allow credentials in CORS requests"
  type        = string
  default     = "false"
}

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}
