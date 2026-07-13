# ==========================================================================
# ローカル値（ルート）
# ==========================================================================
locals {
  environment = "dev"

  common_tags = {
    project     = var.project_name
    environment = local.environment
    managed_by  = "terraform"
  }

  acr_login_server = module.container_registry.acr_login_server
}
