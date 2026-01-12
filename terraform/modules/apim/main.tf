# Azure API Management Module - Infrastructure Only
# @author Shanaka Jayasundera - shanakaj@gmail.com
#
# Creates Azure APIM instance with VNet integration
# API configurations (APIs, operations, policies) are managed by ASO via ArgoCD
#
# Separation of Concerns:
#   - Terraform: APIM infrastructure (this file)
#   - ArgoCD/ASO: API configurations (kubernetes/10-apim-api-config.yaml)

# Azure API Management Instance
resource "azurerm_api_management" "main" {
  name                = "apim-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  sku_name = var.sku_name

  # VNet Integration
  # - Internal: Only accessible within VNet
  # - External: Public IP with VNet backend access
  virtual_network_type = var.virtual_network_type

  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != "None" ? [1] : []
    content {
      subnet_id = var.subnet_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# =============================================================================
# NOTE: API configurations (APIs, operations, policies, products) are now
# managed by Azure Service Operator (ASO) via ArgoCD for GitOps pattern.
#
# See: kubernetes/10-apim-api-config.yaml
# Sync Wave: 9 (after services are deployed)
#
# Benefits:
#   - App teams can manage their own API configurations
#   - API config is version controlled alongside service code
#   - Changes are deployed via GitOps (ArgoCD)
#   - No Terraform changes needed for API updates
# =============================================================================
