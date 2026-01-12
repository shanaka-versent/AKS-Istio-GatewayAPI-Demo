# Network Module - Variables
# @author Shanaka Jayasundera - shanakaj@gmail.com

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

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
}

variable "aks_subnet_cidr" {
  description = "AKS subnet CIDR"
  type        = string
}

variable "appgw_subnet_cidr" {
  description = "App Gateway subnet CIDR"
  type        = string
}

variable "apim_subnet_cidr" {
  description = "Azure API Management subnet CIDR (optional)"
  type        = string
  default     = ""
}

variable "enable_apim_subnet" {
  description = "Enable APIM subnet creation"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
