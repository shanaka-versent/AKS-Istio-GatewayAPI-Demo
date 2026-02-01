# AKS POC - Azure Application Gateway + APIM with Kubernetes Gateway API

This POC demonstrates Azure Application Gateway and API Management integration with Kubernetes Gateway API on AKS using Istio Ambient Mesh and ArgoCD GitOps.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                    │                              │
                    ▼                              ▼
    ┌───────────────────────────┐    ┌───────────────────────────┐
    │   App Gateway (WAF v2)    │    │   API Management          │
    │   - OWASP 3.2 Rules       │    │   - Rate Limiting         │
    │   - Bot Protection        │    │   - Security Headers      │
    │   - SQL/XSS Protection    │    │   - Request Validation    │
    │   Routes: /app1, /app2    │    │   Routes: /api/*          │
    └───────────────────────────┘    └───────────────────────────┘
                    │                              │
                    └──────────────┬───────────────┘
                                   ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                     AKS Cluster (Internal LB)                            │
    │  ┌───────────────────────────────────────────────────────────────────┐  │
    │  │                    Istio Gateway (TLS)                             │  │
    │  │                    HTTPRoutes → Backend Services                   │  │
    │  │                    Istio Ambient Mesh (ztunnel, no sidecars)       │  │
    │  └───────────────────────────────────────────────────────────────────┘  │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Key Technologies

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Ingress (Web)** | Azure Application Gateway WAF v2 | Web traffic, WAF protection |
| **Ingress (API)** | Azure API Management | API traffic, rate limiting, policies |
| **Service Mesh** | Istio Ambient Mesh | mTLS, no sidecars, ztunnel |
| **Routing** | Kubernetes Gateway API | HTTPRoutes (not Ingress resources) |
| **GitOps** | ArgoCD with Sync Waves | All K8s resources |
| **Infrastructure** | Terraform | Azure resources only |

## Traffic Flow

| Traffic Type | Path | Flow |
|--------------|------|------|
| **Web Traffic** | `/app1`, `/app2` | Internet → App Gateway (WAF) → Internal LB → Istio Gateway → Apps |
| **API Traffic** | `/api/*` | Internet → APIM (Policies) → Internal LB → Istio Gateway → APIs |
| **Health Probes** | `/healthz/*` | App Gateway → Internal LB → Istio Gateway → health-responder |

## Security Features

### Application Gateway WAF v2

| Feature | Description |
|---------|-------------|
| OWASP 3.2 Core Rule Set | SQL injection, XSS, command injection protection |
| Bot Protection | Microsoft Bot Manager blocks malicious bots |
| Mode | Prevention (blocks attacks) or Detection (logs only) |

### APIM Security Policies

| Policy | Configuration |
|--------|---------------|
| Rate Limiting | 100 calls/60 sec per IP |
| Request Size Limit | 1 MB max |
| Security Headers | X-Frame-Options, X-Content-Type-Options, X-XSS-Protection |
| Header Stripping | Removes X-Powered-By, Server headers |

### Security Gap: WAF vs APIM

| Threat | App Gateway WAF | APIM Policies |
|--------|-----------------|---------------|
| SQL Injection | ✅ OWASP CRS | ❌ Not covered |
| XSS Attacks | ✅ OWASP CRS | ❌ Not covered |
| Command Injection | ✅ OWASP CRS | ❌ Not covered |
| Bot Attacks | ✅ Bot Manager | ❌ Not covered |
| Rate Limiting | ❌ Limited | ✅ Full support |
| API Quotas | ❌ Not available | ✅ Full support |

> **Note:** APIM lacks WAF-level protection. For production, consider routing APIM through App Gateway. See [Production Enhancement](#production-enhancement-apim-behind-app-gateway) below.

## Quick Start

### Prerequisites

- Azure CLI, Terraform >= 1.5.0, kubectl, kubelogin, openssl

### Deploy

```bash
# 1. Deploy Azure infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# 2. Get AKS credentials
az aks get-credentials --resource-group rg-mtkc-poc --name aks-mtkc-poc
kubelogin convert-kubeconfig -l azurecli

# 3. Generate TLS certificates
./scripts/generate-tls-certs.sh
./scripts/create-tls-secrets.sh

# 4. Deploy ArgoCD Root Application
kubectl apply -f argocd/root-app.yaml

# 5. Update App Gateway backend with Internal LB IP
./scripts/04-update-appgw-backend.sh

# 6. Validate
./tests/validate-poc.sh
```

### Test Endpoints

```bash
# Web Traffic (App Gateway)
curl -k https://<APP_GW_IP>/app1
curl -k https://<APP_GW_IP>/app2

# API Traffic (APIM)
curl https://apim-mtkc-poc.azure-api.net/api/v1/users

# WAF Test (should return 403)
curl -k "https://<APP_GW_IP>/app1?id=1' OR '1'='1"
```

## GitOps with ArgoCD

All Kubernetes resources are managed via ArgoCD with Sync Waves:

| Wave | Component | Why This Order |
|------|-----------|----------------|
| -1 | Istio Base (CRDs) | CRDs must exist before resources use them |
| 0 | Istiod, Istio CNI, ztunnel | Control plane needs CRDs ready |
| 1 | Namespaces (ambient mode) | Need Istio running to apply ambient labels |
| 2 | cert-manager | Certificate infrastructure |
| 3 | Azure Service Operator | Azure operator for APIM APIs |
| 5 | Gateway + LoadBalancer | Needs namespaces and Istio ready |
| 6 | ReferenceGrants + HTTPRoutes | Need Gateway to exist |
| 7 | Applications | Need routes configured |
| 9 | APIM API Configuration (ASO) | Need apps deployed first |

> **Note:** Negative waves are used for infrastructure prerequisites (CRDs, operators). This creates logical separation and makes the sync order self-documenting.

## Production Enhancement: APIM Behind App Gateway

For production environments, routing APIM traffic through Application Gateway provides WAF protection for APIs:

```
Current (POC):     Internet → APIM → Internal LB → APIs
Production:        Internet → App Gateway (WAF) → APIM → Internal LB → APIs
```

### Benefits

- **WAF for APIs**: SQL injection, XSS, command injection protection
- **Single Entry Point**: Unified ingress, simpler NSG rules
- **Bot Protection**: OWASP bot ruleset applies to API traffic
- **Consistent Security**: Same WAF rules for all external traffic

### Implementation Steps

**Step 1: Make APIM Internal-Only**

Update APIM to use internal VNet integration (no public endpoint):

```hcl
# terraform/modules/apim/main.tf
virtual_network_type = "Internal"  # Change from "External"
```

**Step 2: Add APIM Backend Pool to App Gateway**

Configure App Gateway to route `/api/*` traffic to APIM's internal IP:

```hcl
# terraform/modules/app_gateway/main.tf
backend_address_pool {
  name  = "apim-backend-pool"
  fqdns = ["apim-mtkc-poc.azure-api.net"]  # Or internal IP
}

backend_http_settings {
  name                  = "apim-https-settings"
  port                  = 443
  protocol              = "Https"
  pick_host_name_from_backend_address = true
}

request_routing_rule {
  name                       = "api-routing"
  rule_type                  = "PathBasedRouting"
  url_path_map_name          = "api-path-map"
}

url_path_map {
  name                               = "api-path-map"
  default_backend_address_pool_name  = "aks-backend-pool"
  default_backend_http_settings_name = "aks-https-settings"

  path_rule {
    name                       = "api-path"
    paths                      = ["/api/*"]
    backend_address_pool_name  = "apim-backend-pool"
    backend_http_settings_name = "apim-https-settings"
  }
}
```

**Step 3: Update NSG Rules**

Restrict APIM subnet to only accept traffic from App Gateway:

```hcl
# terraform/modules/network/main.tf
resource "azurerm_network_security_rule" "apim_from_appgw_only" {
  name                        = "AllowFromAppGatewayOnly"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.appgw_subnet_cidr  # Only App Gateway
  destination_port_range      = "443"
  # ... deny all other inbound on 443
}
```

> **Trade-off**: This adds ~1-5ms latency per request but provides comprehensive WAF protection for all API traffic.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Backend unhealthy | Check HTTPRoute for `/healthz`, verify health-responder running |
| 502 errors | Check Gateway logs, verify HTTPRoutes attached |
| 403 from WAF | Check WAF logs, use Detection mode for testing |
| 429 from APIM | Rate limit exceeded, wait or adjust limits |
| Sidecars present | Add `istio.io/dataplane-mode: ambient` label to namespace |

---

**Author:** Shanaka Jayasundera (shanakaj@gmail.com)
