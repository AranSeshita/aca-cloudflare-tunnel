# ==========================================================================
# ACA + Cloudflare 構成
# ==========================================================================

# --- 基盤 -----------------------------------------------------------------
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

# --- レジストリ / NAT / ID -------------------------------------------------
module "container_registry" {
  source = "../../modules/container_registry"

  # ACR は PE 不要。公開エンドポイント + Managed Identity / token 認証で利用する。
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

# --- Container Apps Environment（internal・完全閉域） ---------------------
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


# --- ACA: バックエンド -----------------------------------------------------
module "aca_backend" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-api"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id
  revision_mode                = "Single" # CI 単一イメージ運用。最新 active リビジョンへ自動 100%（カナリアが要る場合は Multiple へ変更可。要 CD トラフィック制御）

  container_name = "api"
  # Backend = 疎通先の応答役（既定 containerapps-helloworld）。実アプリへ差し替えるなら
  # var.backend_image を ACR のイメージにする（registry は下で設定済み）。
  image  = var.backend_image
  cpu    = 0.5
  memory = "1Gi"

  identity_type        = "UserAssigned"
  identity_ids         = [module.id_backend.id]
  registry_server      = local.acr_login_server
  registry_identity_id = module.id_backend.id

  env_vars = var.app_storage_env

  # helloworld は 80 待受（PORT を読まない）。実アプリに変えたら待受ポートに合わせる。
  ingress      = { external_enabled = false, target_port = 80 }
  min_replicas = 1
  max_replicas = 3
  tags         = local.common_tags
}

# --- ACA: フロントエンド ---------------------------------------------------
module "aca_frontend" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-web"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id
  revision_mode                = "Single" # CI 単一イメージ運用。最新 active リビジョンへ自動 100%（カナリアが要る場合は Multiple へ変更可。要 CD トラフィック制御）

  container_name = "web"
  # Frontend = Network Tester。Tunnel 経由で開き、UI から BACKEND_URL（backend の内部 FQDN）へ
  # 疎通確認する。実アプリへ差し替えるなら var.frontend_image を ACR のイメージにする。
  image  = var.frontend_image
  cpu    = 0.5
  memory = "1Gi"

  identity_type        = "UserAssigned"
  identity_ids         = [module.id_frontend.id]
  registry_server      = local.acr_login_server
  registry_identity_id = module.id_frontend.id

  # Network Tester の UI にこの URL を入力して backend への疎通を確認する。
  env_vars = {
    BACKEND_URL = "https://${module.aca_backend.fqdn}"
  }

  ingress      = { external_enabled = false, target_port = 8080 } # Network Tester は 8080 待受
  min_replicas = 1
  max_replicas = 3
  tags         = local.common_tags
}

# --- Cloudflare Tunnel + ルーティング --------------------------------------
# WAF は Cloudflare ダッシュボードで運用する。
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
      create_dns = true # proxied CNAME を Terraform で作成
    }
  ]
}

# --- ACA: Cloudflared（Tunnel コネクタ） -----------------------------------
module "aca_cloudflared" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-cfd"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id

  container_name = "cloudflared"
  image          = var.cloudflared_image # 公開イメージ（ACR 不要）
  args           = ["tunnel", "--no-autoupdate", "run", "--token", "$(TUNNEL_TOKEN)"]

  # Azure リソースへアクセスしないため SystemAssigned（ロール付与なし）。
  identity_type = "SystemAssigned"

  env_secrets = { TUNNEL_TOKEN = "tunnel-token" }
  secrets     = { tunnel-token = { value = module.cloudflare.tunnel_token } }

  ingress      = null # アウトバウンド接続のみ
  min_replicas = 2    # コネクタ冗長化（SPOF 回避）
  max_replicas = 3
  tags         = local.common_tags
}
