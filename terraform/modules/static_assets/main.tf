# Azure Blob Storage for Static Assets
# Equivalent to AWS S3 for CloudFront origin

resource "azurerm_storage_account" "static_assets" {
  name                     = replace("${var.name_prefix}static${var.suffix}", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable static website hosting
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "OPTIONS"]
      allowed_origins    = var.allowed_origins
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = var.tags
}

# Container for static assets
resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_id    = azurerm_storage_account.static_assets.id
  container_access_type = "blob" # Public read access for blobs
}

# Upload sample CSS
resource "azurerm_storage_blob" "styles_css" {
  count                  = var.upload_sample_assets ? 1 : 0
  name                   = "css/styles.css"
  storage_account_name   = azurerm_storage_account.static_assets.name
  storage_container_name = azurerm_storage_container.static.name
  type                   = "Block"
  content_type           = "text/css"
  source_content         = <<-EOF
/* MTKC POC - Static Assets Demo Styles */
:root {
  --primary-color: #0078d4;
  --secondary-color: #50e6ff;
  --background-dark: #1a1a2e;
  --background-light: #16213e;
  --text-primary: #ffffff;
  --text-secondary: #a0aec0;
  --success-color: #10b981;
  --warning-color: #f59e0b;
  --error-color: #ef4444;
  --border-radius: 12px;
  --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  background: linear-gradient(135deg, var(--background-dark) 0%, var(--background-light) 100%);
  color: var(--text-primary);
  min-height: 100vh;
  line-height: 1.6;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.header {
  text-align: center;
  padding: 3rem 0;
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  border-radius: var(--border-radius);
  margin-bottom: 2rem;
  box-shadow: var(--shadow);
}

.header h1 {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.header p {
  font-size: 1.1rem;
  opacity: 0.9;
}

.logo {
  width: 120px;
  height: 120px;
  margin-bottom: 1rem;
}

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.card {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: var(--border-radius);
  padding: 1.5rem;
  backdrop-filter: blur(10px);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.2);
}

.card h2 {
  color: var(--secondary-color);
  margin-bottom: 1rem;
  font-size: 1.3rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.card ul {
  list-style: none;
  padding-left: 0;
}

.card li {
  padding: 0.5rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  color: var(--text-secondary);
}

.card li:last-child {
  border-bottom: none;
}

.badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
}

.badge-success { background: var(--success-color); color: white; }
.badge-warning { background: var(--warning-color); color: black; }
.badge-error { background: var(--error-color); color: white; }
.badge-info { background: var(--primary-color); color: white; }

.architecture-diagram {
  background: rgba(0, 0, 0, 0.3);
  border-radius: var(--border-radius);
  padding: 2rem;
  margin: 2rem 0;
  font-family: 'Courier New', monospace;
  font-size: 0.9rem;
  overflow-x: auto;
  white-space: pre;
  line-height: 1.4;
}

.image-gallery {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
}

.image-gallery img {
  width: 100%;
  height: 150px;
  object-fit: cover;
  border-radius: 8px;
  border: 2px solid rgba(255, 255, 255, 0.1);
  transition: transform 0.3s ease;
}

.image-gallery img:hover {
  transform: scale(1.05);
}

.server-info {
  background: rgba(0, 120, 212, 0.1);
  border: 1px solid var(--primary-color);
  border-radius: var(--border-radius);
  padding: 1rem;
  margin-top: 2rem;
}

.server-info h3 {
  color: var(--primary-color);
  margin-bottom: 0.5rem;
}

.server-info code {
  background: rgba(0, 0, 0, 0.3);
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.9rem;
}

.footer {
  text-align: center;
  padding: 2rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .cards {
    grid-template-columns: 1fr;
  }

  .header h1 {
    font-size: 1.8rem;
  }
}
EOF
}

# Upload sample JavaScript
resource "azurerm_storage_blob" "app_js" {
  count                  = var.upload_sample_assets ? 1 : 0
  name                   = "js/app.js"
  storage_account_name   = azurerm_storage_account.static_assets.name
  storage_container_name = azurerm_storage_container.static.name
  type                   = "Block"
  content_type           = "application/javascript"
  source_content         = <<-EOF
// MTKC POC - Static Assets Demo JavaScript
console.log('MTKC POC - Static assets loaded from Azure Blob Storage');
console.log('Cached via Azure Front Door CDN');

// Display load time and cache status
document.addEventListener('DOMContentLoaded', function() {
  const loadTime = performance.now().toFixed(2);
  console.log('Page loaded in ' + loadTime + 'ms');

  // Update timestamp
  const timestampEl = document.getElementById('timestamp');
  if (timestampEl) {
    timestampEl.textContent = new Date().toISOString();
  }

  // Check if served from cache
  if (performance.getEntriesByType) {
    const resources = performance.getEntriesByType('resource');
    resources.forEach(function(resource) {
      if (resource.name.includes('/static/')) {
        console.log('Resource: ' + resource.name);
        console.log('  Transfer Size: ' + resource.transferSize + ' bytes');
        console.log('  Cached: ' + (resource.transferSize === 0 ? 'Yes (from cache)' : 'No'));
      }
    });
  }

  // Add interactivity to cards
  const cards = document.querySelectorAll('.card');
  cards.forEach(function(card) {
    card.addEventListener('click', function() {
      this.classList.toggle('expanded');
    });
  });

  // Image lazy loading
  const images = document.querySelectorAll('img[data-src]');
  const imageObserver = new IntersectionObserver(function(entries, observer) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) {
        const img = entry.target;
        img.src = img.dataset.src;
        img.removeAttribute('data-src');
        observer.unobserve(img);
      }
    });
  });

  images.forEach(function(img) {
    imageObserver.observe(img);
  });
});

// Fetch API health status
async function checkApiHealth() {
  try {
    const response = await fetch('/api/health');
    const data = await response.json();
    console.log('API Health:', data);
    return data;
  } catch (error) {
    console.log('API not available:', error.message);
    return { status: 'unavailable' };
  }
}

// Export for use in HTML
window.MTKC = {
  checkApiHealth: checkApiHealth,
  version: '1.0.0',
  environment: 'Azure AKS + Front Door'
};
EOF
}

# Upload sample logo SVG
resource "azurerm_storage_blob" "logo_svg" {
  count                  = var.upload_sample_assets ? 1 : 0
  name                   = "images/logo.svg"
  storage_account_name   = azurerm_storage_account.static_assets.name
  storage_container_name = azurerm_storage_container.static.name
  type                   = "Block"
  content_type           = "image/svg+xml"
  source_content         = <<-EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0078d4;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#50e6ff;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="grad2" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#00bcf2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#00b294;stop-opacity:1" />
    </linearGradient>
  </defs>

  <!-- Background circle -->
  <circle cx="100" cy="100" r="95" fill="url(#grad1)" opacity="0.1"/>
  <circle cx="100" cy="100" r="90" fill="none" stroke="url(#grad1)" stroke-width="2"/>

  <!-- Azure cloud shape -->
  <path d="M60 130 Q40 130 40 110 Q40 90 60 90 Q60 70 85 70 Q110 70 115 90 Q140 85 150 105 Q160 125 140 135 Q130 140 60 130"
        fill="url(#grad2)" opacity="0.9"/>

  <!-- Network nodes -->
  <circle cx="70" cy="105" r="8" fill="white"/>
  <circle cx="100" cy="95" r="8" fill="white"/>
  <circle cx="130" cy="110" r="8" fill="white"/>

  <!-- Connection lines -->
  <line x1="70" y1="105" x2="100" y2="95" stroke="white" stroke-width="2" opacity="0.7"/>
  <line x1="100" y1="95" x2="130" y2="110" stroke="white" stroke-width="2" opacity="0.7"/>

  <!-- Text -->
  <text x="100" y="165" text-anchor="middle" font-family="Segoe UI, sans-serif" font-size="16" font-weight="bold" fill="#0078d4">MTKC POC</text>
  <text x="100" y="182" text-anchor="middle" font-family="Segoe UI, sans-serif" font-size="10" fill="#666">Azure + AKS + Istio</text>
</svg>
EOF
}

# Upload sample architecture image
resource "azurerm_storage_blob" "architecture_png" {
  count                  = var.upload_sample_assets ? 1 : 0
  name                   = "images/architecture.svg"
  storage_account_name   = azurerm_storage_account.static_assets.name
  storage_container_name = azurerm_storage_container.static.name
  type                   = "Block"
  content_type           = "image/svg+xml"
  source_content         = <<-EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400">
  <defs>
    <linearGradient id="azureGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0078d4"/>
      <stop offset="100%" style="stop-color:#50e6ff"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="800" height="400" fill="#1a1a2e"/>

  <!-- Front Door -->
  <rect x="300" y="20" width="200" height="60" rx="8" fill="url(#azureGrad)"/>
  <text x="400" y="55" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="14" font-weight="bold">Azure Front Door</text>

  <!-- Arrows -->
  <path d="M350 80 L350 120" stroke="#50e6ff" stroke-width="2" marker-end="url(#arrow)"/>
  <path d="M450 80 L450 120" stroke="#50e6ff" stroke-width="2"/>

  <!-- Blob Storage -->
  <rect x="100" y="130" width="150" height="50" rx="6" fill="#00bcf2"/>
  <text x="175" y="160" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="12">Blob Storage</text>

  <!-- App Gateway -->
  <rect x="325" y="130" width="150" height="50" rx="6" fill="#0078d4"/>
  <text x="400" y="160" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="12">App Gateway</text>

  <!-- APIM -->
  <rect x="550" y="130" width="150" height="50" rx="6" fill="#68217a"/>
  <text x="625" y="160" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="12">API Management</text>

  <!-- AKS Cluster -->
  <rect x="200" y="230" width="400" height="150" rx="10" fill="none" stroke="#0078d4" stroke-width="2" stroke-dasharray="5,5"/>
  <text x="400" y="255" text-anchor="middle" fill="#0078d4" font-family="Segoe UI" font-size="12">AKS Cluster</text>

  <!-- Istio Gateway -->
  <rect x="325" y="270" width="150" height="40" rx="6" fill="#466bb0"/>
  <text x="400" y="295" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="11">Istio Gateway</text>

  <!-- Apps -->
  <rect x="230" y="330" width="80" height="35" rx="4" fill="#10b981"/>
  <text x="270" y="352" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="10">App 1</text>

  <rect x="360" y="330" width="80" height="35" rx="4" fill="#10b981"/>
  <text x="400" y="352" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="10">App 2</text>

  <rect x="490" y="330" width="80" height="35" rx="4" fill="#f59e0b"/>
  <text x="530" y="352" text-anchor="middle" fill="white" font-family="Segoe UI" font-size="10">API</text>

  <!-- Connection lines -->
  <line x1="300" y1="50" x2="175" y2="130" stroke="#50e6ff" stroke-width="1.5"/>
  <line x1="400" y1="180" x2="400" y2="270" stroke="#50e6ff" stroke-width="1.5"/>
  <line x1="400" y1="310" x2="270" y2="330" stroke="#50e6ff" stroke-width="1"/>
  <line x1="400" y1="310" x2="400" y2="330" stroke="#50e6ff" stroke-width="1"/>
  <line x1="400" y1="310" x2="530" y2="330" stroke="#50e6ff" stroke-width="1"/>

  <!-- Labels -->
  <text x="140" y="115" fill="#a0aec0" font-family="Segoe UI" font-size="10">/static/*</text>
  <text x="360" y="115" fill="#a0aec0" font-family="Segoe UI" font-size="10">/app*</text>
  <text x="580" y="115" fill="#a0aec0" font-family="Segoe UI" font-size="10">/api/*</text>
</svg>
EOF
}

# Upload sample hero image
resource "azurerm_storage_blob" "hero_image" {
  count                  = var.upload_sample_assets ? 1 : 0
  name                   = "images/hero.svg"
  storage_account_name   = azurerm_storage_account.static_assets.name
  storage_container_name = azurerm_storage_container.static.name
  type                   = "Block"
  content_type           = "image/svg+xml"
  source_content         = <<-EOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 400">
  <defs>
    <linearGradient id="heroGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0078d4"/>
      <stop offset="50%" style="stop-color:#00bcf2"/>
      <stop offset="100%" style="stop-color:#50e6ff"/>
    </linearGradient>
    <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
      <path d="M 40 0 L 0 0 0 40" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="1"/>
    </pattern>
  </defs>

  <!-- Background -->
  <rect width="1200" height="400" fill="url(#heroGrad)"/>
  <rect width="1200" height="400" fill="url(#grid)"/>

  <!-- Floating elements -->
  <circle cx="100" cy="100" r="60" fill="rgba(255,255,255,0.1)"/>
  <circle cx="1100" cy="300" r="80" fill="rgba(255,255,255,0.1)"/>
  <circle cx="600" cy="350" r="40" fill="rgba(255,255,255,0.1)"/>

  <!-- Main text -->
  <text x="600" y="180" text-anchor="middle" font-family="Segoe UI" font-size="48" font-weight="bold" fill="white">Azure AKS + Istio + Gateway API</text>
  <text x="600" y="230" text-anchor="middle" font-family="Segoe UI" font-size="24" fill="rgba(255,255,255,0.9)">Enterprise API Gateway Architecture Demo</text>

  <!-- Feature badges -->
  <rect x="300" y="270" width="120" height="36" rx="18" fill="rgba(255,255,255,0.2)"/>
  <text x="360" y="293" text-anchor="middle" font-family="Segoe UI" font-size="12" fill="white">Front Door CDN</text>

  <rect x="440" y="270" width="120" height="36" rx="18" fill="rgba(255,255,255,0.2)"/>
  <text x="500" y="293" text-anchor="middle" font-family="Segoe UI" font-size="12" fill="white">Blob Storage</text>

  <rect x="580" y="270" width="120" height="36" rx="18" fill="rgba(255,255,255,0.2)"/>
  <text x="640" y="293" text-anchor="middle" font-family="Segoe UI" font-size="12" fill="white">Istio Ambient</text>

  <rect x="720" y="270" width="120" height="36" rx="18" fill="rgba(255,255,255,0.2)"/>
  <text x="780" y="293" text-anchor="middle" font-family="Segoe UI" font-size="12" fill="white">GitOps Ready</text>
</svg>
EOF
}
