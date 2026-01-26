# Static Assets Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "suffix" {
  description = "Random suffix for unique naming"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "upload_sample_assets" {
  description = "Whether to upload sample static assets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
