# ==========================================================================
# ACA + Cloudflare configuration
# ==========================================================================

# --- Foundation -------------------------------------------------------------
module "resource_group" {
  source = "../../modules/resource_group"

  name     = "rg-${var.project_name}-${local.environment}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "../../modules/network"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.common_tags
}

module "monitor" {
  source = "../../modules/monitor"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  tags                = local.common_tags
}

# --- Registry / NAT / identities ---------------------------------------------
module "container_registry" {
  source = "../../modules/container_registry"

  # ACR needs no Private Endpoint: it is accessed via its public endpoint with
  # Managed Identity / token auth.
  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  project_name               = var.project_name
  environment                = local.environment
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "nat_gateway" {
  source = "../../modules/nat_gateway"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  subnets             = { aca = module.network.subnet_ids["aca"] }
  tags                = local.common_tags
}

module "id_frontend" {
  source = "../../modules/user_assigned_identity"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  suffix              = "-web"

  role_assignments = {
    acr_pull = { scope = module.container_registry.acr_id, role_definition_name = "AcrPull" }
  }
  tags = local.common_tags
}

module "id_backend" {
  source = "../../modules/user_assigned_identity"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  suffix              = "-api"

  role_assignments = {
    acr_pull = { scope = module.container_registry.acr_id, role_definition_name = "AcrPull" }
  }
  tags = local.common_tags
}

# --- Container Apps Environment (internal, fully private) --------------------
module "cae" {
  source = "../../modules/container_app_environment"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  project_name               = var.project_name
  environment                = local.environment
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  infrastructure_subnet_id   = module.network.subnet_ids["aca"]
  tags                       = local.common_tags
}


# --- ACA: backend -------------------------------------------------------------
module "aca_backend" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-api"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id
  revision_mode                = "Single" # Single-image CI flow: 100% traffic goes to the latest active revision automatically (switch to Multiple for canary; requires CD-side traffic control)

  container_name = "api"
  # Backend = connectivity-check responder (default: containerapps-helloworld).
  # To use a real app, point var.backend_image at an ACR image (registry is configured below).
  image  = var.backend_image
  cpu    = 0.5
  memory = "1Gi"

  identity_type        = "UserAssigned"
  identity_ids         = [module.id_backend.id]
  registry_server      = local.acr_login_server
  registry_identity_id = module.id_backend.id

  env_vars = var.app_storage_env

  # helloworld listens on port 80 (it ignores PORT). Match target_port to your app's listening port when you swap it.
  ingress      = { external_enabled = false, target_port = 80 }
  min_replicas = 1
  max_replicas = 3
  tags         = local.common_tags
}

# --- ACA: frontend ------------------------------------------------------------
module "aca_frontend" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-web"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id
  revision_mode                = "Single" # Single-image CI flow: 100% traffic goes to the latest active revision automatically (switch to Multiple for canary; requires CD-side traffic control)

  container_name = "web"
  # Frontend = Network Tester. Open it through the Tunnel and use the UI to probe
  # BACKEND_URL (the backend's internal FQDN). To use a real app, point var.frontend_image at an ACR image.
  image  = var.frontend_image
  cpu    = 0.5
  memory = "1Gi"

  identity_type        = "UserAssigned"
  identity_ids         = [module.id_frontend.id]
  registry_server      = local.acr_login_server
  registry_identity_id = module.id_frontend.id

  # Enter this URL in the Network Tester UI to verify connectivity to the backend.
  env_vars = {
    BACKEND_URL = "https://${module.aca_backend.fqdn}"
  }

  ingress      = { external_enabled = false, target_port = 8080 } # Network Tester listens on 8080
  min_replicas = 1
  max_replicas = 3
  tags         = local.common_tags
}

# --- Cloudflare Tunnel + routing ----------------------------------------------
# WAF is managed in the Cloudflare dashboard.
module "cloudflare" {
  source = "../../modules/cloudflare"

  account_id   = var.cloudflare_account_id
  zone_id      = var.cloudflare_zone_id
  project_name = var.project_name
  environment  = local.environment

  ingress_rules = [
    {
      hostname   = var.public_hostname
      service    = "https://${module.aca_frontend.fqdn}"
      create_dns = true # Terraform creates the proxied CNAME
    }
  ]
}

# --- ACA: cloudflared (Tunnel connector) ---------------------------------------
module "aca_cloudflared" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-cfd"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id

  container_name = "cloudflared"
  image          = var.cloudflared_image # Public image (no ACR needed)
  args           = ["tunnel", "--no-autoupdate", "run", "--token", "$(TUNNEL_TOKEN)"]

  # SystemAssigned with no role assignments: it never accesses Azure resources.
  identity_type = "SystemAssigned"

  env_secrets = { TUNNEL_TOKEN = "tunnel-token" }
  secrets     = { tunnel-token = { value = module.cloudflare.tunnel_token } }

  ingress      = null # Outbound-only Tunnel connections
  min_replicas = 2    # Redundant connectors (avoid a SPOF)
  max_replicas = 3
  tags         = local.common_tags
}
