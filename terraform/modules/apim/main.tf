# Azure API Management Module - Infrastructure Only
# @author Shanaka Jayasundera - shanakaj@gmail.com
#
# Creates Azure APIM instance with VNet integration and global security policies
# API configurations (APIs, operations, policies) are managed by ASO via ArgoCD
#
# Separation of Concerns:
#   - Terraform: APIM infrastructure + global security policies (this file)
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

  # Security: Minimum TLS version
  min_api_version = "2021-08-01"

  # Security: Protocols
  protocols {
    enable_http2 = true
  }

  # Security: Sign-up and sign-in settings
  sign_up {
    enabled = false
    terms_of_service {
      enabled          = false
      consent_required = false
    }
  }

  tags = var.tags
}

# =============================================================================
# Global Security Policies
# These policies apply to ALL APIs as a baseline security layer
# =============================================================================
resource "azurerm_api_management_policy" "global" {
  count             = var.enable_global_policy ? 1 : 0
  api_management_id = azurerm_api_management.main.id

  xml_content = <<-XML
    <policies>
      <inbound>
        <!-- Rate Limiting: ${var.rate_limit_calls} calls per ${var.rate_limit_period} seconds per IP -->
        <rate-limit-by-key calls="${var.rate_limit_calls}"
                          renewal-period="${var.rate_limit_period}"
                          counter-key="@(context.Request.IpAddress)"
                          increment-condition="@(context.Response.StatusCode >= 200 && context.Response.StatusCode < 300)" />

        <!-- Request Size Limit: ${var.max_request_body_size} bytes -->
        <set-variable name="maxBodySize" value="${var.max_request_body_size}" />
        <choose>
          <when condition="@(context.Request.Body != null && context.Request.Body.As<string>(preserveContent: true).Length > ${var.max_request_body_size})">
            <return-response>
              <set-status code="413" reason="Payload Too Large" />
              <set-header name="Content-Type" exists-action="override">
                <value>application/json</value>
              </set-header>
              <set-body>{"error": "Request body exceeds maximum allowed size of ${var.max_request_body_size} bytes"}</set-body>
            </return-response>
          </when>
        </choose>

        <!-- Security Headers -->
        <set-header name="X-Content-Type-Options" exists-action="override">
          <value>nosniff</value>
        </set-header>

        <!-- Remove sensitive headers from request -->
        <set-header name="X-Powered-By" exists-action="delete" />
        <set-header name="Server" exists-action="delete" />

        <!-- CORS (if enabled) -->
        %{if var.enable_cors}
        <cors allow-credentials="${var.cors_allow_credentials}">
          <allowed-origins>
            %{for origin in var.cors_allowed_origins}
            <origin>${origin}</origin>
            %{endfor}
          </allowed-origins>
          <allowed-methods>
            <method>GET</method>
            <method>POST</method>
            <method>PUT</method>
            <method>DELETE</method>
            <method>PATCH</method>
            <method>OPTIONS</method>
          </allowed-methods>
          <allowed-headers>
            <header>Content-Type</header>
            <header>Authorization</header>
            <header>X-Requested-With</header>
          </allowed-headers>
        </cors>
        %{endif}

        <base />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <!-- Security Headers -->
        <set-header name="X-Frame-Options" exists-action="override">
          <value>DENY</value>
        </set-header>
        <set-header name="X-Content-Type-Options" exists-action="override">
          <value>nosniff</value>
        </set-header>
        <set-header name="X-XSS-Protection" exists-action="override">
          <value>1; mode=block</value>
        </set-header>
        <set-header name="Referrer-Policy" exists-action="override">
          <value>strict-origin-when-cross-origin</value>
        </set-header>

        <!-- Remove internal headers -->
        <set-header name="X-Powered-By" exists-action="delete" />
        <set-header name="X-AspNet-Version" exists-action="delete" />

        <base />
      </outbound>
      <on-error>
        <!-- Generic error response to avoid information disclosure -->
        <set-header name="X-Content-Type-Options" exists-action="override">
          <value>nosniff</value>
        </set-header>
        <base />
      </on-error>
    </policies>
  XML
}

# =============================================================================
# Named Values (Secrets) - For future JWT/API Key validation
# =============================================================================
resource "azurerm_api_management_named_value" "rate_limit_key" {
  count               = var.enable_global_policy ? 1 : 0
  name                = "rate-limit-key"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.main.name
  display_name        = "Rate Limit Key"
  value               = "rate-limit-${var.name_prefix}"
  secret              = false
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
