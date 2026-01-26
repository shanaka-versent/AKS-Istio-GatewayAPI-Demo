# Azure Front Door with CDN Caching
# Equivalent to AWS CloudFront for edge caching

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.name_prefix}-fd"
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  tags = var.tags
}

# ============================================
# Origin Groups
# ============================================

# Origin Group for Static Assets (Blob Storage)
resource "azurerm_cdn_frontdoor_origin_group" "static_assets" {
  name                     = "static-assets-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin Group for App Gateway (Web Traffic)
resource "azurerm_cdn_frontdoor_origin_group" "app_gateway" {
  name                     = "app-gateway-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/healthz/ready"
    request_type        = "GET"
    protocol            = "Https"
    interval_in_seconds = 30
  }
}

# Origin Group for APIM (API Traffic) - Optional
resource "azurerm_cdn_frontdoor_origin_group" "apim" {
  count                    = var.enable_apim_origin ? 1 : 0
  name                     = "apim-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/status-0123456789abcdef"
    request_type        = "GET"
    protocol            = "Https"
    interval_in_seconds = 60
  }
}

# ============================================
# Origins
# ============================================

# Static Assets Origin (Blob Storage)
resource "azurerm_cdn_frontdoor_origin" "static_assets" {
  name                          = "static-assets-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_assets.id

  enabled                        = true
  host_name                      = var.blob_storage_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.blob_storage_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# App Gateway Origin
resource "azurerm_cdn_frontdoor_origin" "app_gateway" {
  name                          = "app-gateway-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.app_gateway.id

  enabled                        = true
  host_name                      = var.app_gateway_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.app_gateway_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false # Self-signed cert
}

# APIM Origin (Optional)
resource "azurerm_cdn_frontdoor_origin" "apim" {
  count                         = var.enable_apim_origin ? 1 : 0
  name                          = "apim-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim[0].id

  enabled                        = true
  host_name                      = var.apim_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.apim_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# ============================================
# Endpoints
# ============================================

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.name_prefix}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = var.tags
}

# ============================================
# Rule Sets for Caching
# ============================================

resource "azurerm_cdn_frontdoor_rule_set" "static_caching" {
  name                     = "StaticAssetsCaching"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

# Rule: Cache static assets aggressively
resource "azurerm_cdn_frontdoor_rule" "cache_static" {
  name                      = "CacheStaticAssets"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.static_caching.id
  order                     = 1
  behavior_on_match         = "Continue"

  conditions {
    url_file_extension_condition {
      operator         = "Equal"
      match_values     = ["css", "js", "svg", "png", "jpg", "jpeg", "gif", "webp", "woff", "woff2", "ttf", "ico"]
      negate_condition = false
      transforms       = ["Lowercase"]
    }
  }

  actions {
    route_configuration_override_action {
      cache_behavior                = "OverrideAlways"
      cache_duration                = "365.00:00:00" # 1 year
      compression_enabled           = true
      query_string_caching_behavior = "IgnoreQueryString"
    }

    response_header_action {
      header_action = "Overwrite"
      header_name   = "Cache-Control"
      value         = "public, max-age=31536000, immutable"
    }

    response_header_action {
      header_action = "Append"
      header_name   = "X-Cache-Status"
      value         = "HIT-STATIC"
    }
  }
}

# Rule: Add security headers
resource "azurerm_cdn_frontdoor_rule" "security_headers" {
  name                      = "SecurityHeaders"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.static_caching.id
  order                     = 2
  behavior_on_match         = "Continue"

  actions {
    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-Content-Type-Options"
      value         = "nosniff"
    }

    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-Frame-Options"
      value         = "DENY"
    }

    response_header_action {
      header_action = "Overwrite"
      header_name   = "X-Served-By"
      value         = "Azure-Front-Door-MTKC-POC"
    }
  }
}

# ============================================
# Routes
# ============================================

# Route: Static assets to Blob Storage (cached)
resource "azurerm_cdn_frontdoor_route" "static_assets" {
  name                          = "static-assets-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_assets.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_assets.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.static_caching.id]

  enabled                = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/static/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = [
      "text/css",
      "text/javascript",
      "application/javascript",
      "application/json",
      "image/svg+xml",
      "text/plain",
      "text/html"
    ]
  }
}

# Route: Web traffic to App Gateway (not cached)
resource "azurerm_cdn_frontdoor_route" "web_traffic" {
  name                          = "web-traffic-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.app_gateway.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app_gateway.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.static_caching.id]

  enabled                = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true

  # No caching for dynamic content
  cache {
    query_string_caching_behavior = "UseQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "application/json"]
  }
}

# Route: API traffic to APIM (not cached) - Optional
resource "azurerm_cdn_frontdoor_route" "api_traffic" {
  count                         = var.enable_apim_origin ? 1 : 0
  name                          = "api-traffic-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.apim[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.apim[0].id]

  enabled                = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/api/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true

  # No caching for API
}

# ============================================
# WAF Policy (Optional)
# ============================================

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  count               = var.enable_waf ? 1 : 0
  name                = replace("${var.name_prefix}-waf", "-", "")
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled             = true
  mode                = var.waf_mode

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  count                    = var.enable_waf ? 1 : 0
  name                     = "waf-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.main[0].id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
