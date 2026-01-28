# Private Link Module for Front Door Premium
# @author Shanaka Jayasundera - shanakaj@gmail.com
#
# Creates Private Link Service for AKS Internal Load Balancer
# This allows Azure Front Door Premium to connect privately to the Internal LB

# =============================================================================
# Private Link Subnet (dedicated subnet for Private Link Service)
# =============================================================================

resource "azurerm_subnet" "private_link" {
  name                 = "snet-private-link"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.private_link_subnet_cidr]

  # Required for Private Link Service
  private_link_service_network_policies_enabled = false
}

# =============================================================================
# Private Link Service for Internal Load Balancer
# =============================================================================

# Note: This requires the Internal LB to exist (created by Kubernetes/Istio)
# The lb_frontend_ip_configuration_id is obtained from the K8s-created ILB

resource "azurerm_private_link_service" "internal_lb" {
  count               = var.enable_internal_lb_pls ? 1 : 0
  name                = "${var.name_prefix}-pls-ilb"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Auto-approve connections from Front Door
  auto_approval_subscription_ids              = [var.subscription_id]
  visibility_subscription_ids                 = [var.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [var.lb_frontend_ip_configuration_id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.private_link.id
    primary                    = true
  }

  tags = var.tags
}

# =============================================================================
# Private Endpoint for APIM (when APIM is Internal)
# =============================================================================

resource "azurerm_private_endpoint" "apim" {
  count               = var.enable_apim_private_endpoint ? 1 : 0
  name                = "${var.name_prefix}-pe-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_link.id

  private_service_connection {
    name                           = "${var.name_prefix}-apim-connection"
    private_connection_resource_id = var.apim_id
    subresource_names              = ["Gateway"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# =============================================================================
# Private DNS Zone for APIM (when using Private Endpoint)
# =============================================================================

resource "azurerm_private_dns_zone" "apim" {
  count               = var.enable_apim_private_endpoint ? 1 : 0
  name                = "privatelink.azure-api.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "apim" {
  count                 = var.enable_apim_private_endpoint ? 1 : 0
  name                  = "${var.name_prefix}-apim-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.apim[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_dns_a_record" "apim" {
  count               = var.enable_apim_private_endpoint ? 1 : 0
  name                = var.apim_name
  zone_name           = azurerm_private_dns_zone.apim[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.apim[0].private_service_connection[0].private_ip_address]
}
