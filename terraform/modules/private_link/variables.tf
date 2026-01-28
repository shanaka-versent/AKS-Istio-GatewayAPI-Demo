# Private Link Module Variables
# @author Shanaka Jayasundera - shanakaj@gmail.com

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (for auto-approval)"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network ID"
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
}

variable "private_link_subnet_cidr" {
  description = "CIDR for Private Link subnet"
  type        = string
  default     = "10.0.4.0/24"
}

# Internal Load Balancer Private Link Service
variable "enable_internal_lb_pls" {
  description = "Enable Private Link Service for Internal Load Balancer"
  type        = bool
  default     = false
}

variable "lb_frontend_ip_configuration_id" {
  description = "Frontend IP Configuration ID of the Internal Load Balancer (obtained from K8s deployment)"
  type        = string
  default     = ""
}

# APIM Private Endpoint
variable "enable_apim_private_endpoint" {
  description = "Enable Private Endpoint for APIM"
  type        = bool
  default     = false
}

variable "apim_id" {
  description = "APIM resource ID"
  type        = string
  default     = ""
}

variable "apim_name" {
  description = "APIM name (for DNS record)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
