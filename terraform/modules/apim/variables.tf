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
