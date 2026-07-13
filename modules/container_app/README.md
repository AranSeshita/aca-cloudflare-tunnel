# container_app

再利用可能な Azure Container App モジュール。1 アプリ = 1 呼び出しで構築する。
このサンプルでは **web / api / cloudflared** の 3 アプリをすべてこのモジュールで作る。

- 単一コンテナ + 環境変数 / Secret（インライン値）
- Managed Identity（System / User Assigned）による ACR Pull
- Ingress あり（内部）/ なし（headless）の切り替え
- KEDA カスタムスケールルール、scale-to-zero（`min_replicas = 0`）にも対応

## Usage

### Frontend / Backend（内部 Ingress）

```hcl
module "aca_frontend" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-web"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id

  container_name = "web"
  image          = "${module.container_registry.acr_login_server}/frontend:1.0.0"
  cpu            = 0.5
  memory         = "1Gi"

  identity_type        = "UserAssigned"
  identity_ids         = [module.id_frontend.id]
  registry_server      = module.container_registry.acr_login_server
  registry_identity_id = module.id_frontend.id

  ingress      = { external_enabled = false, target_port = 8080 }
  min_replicas = 1
  max_replicas = 3
  tags         = local.common_tags
}
```

### Cloudflared（headless / Ingress なし）

```hcl
module "aca_cloudflared" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-cfd"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id

  container_name = "cloudflared"
  image          = "docker.io/cloudflare/cloudflared:2026.5.0"
  args           = ["tunnel", "--no-autoupdate", "run", "--token", "$(TUNNEL_TOKEN)"]

  identity_type = "SystemAssigned"
  env_secrets   = { TUNNEL_TOKEN = "tunnel-token" }
  secrets       = { tunnel-token = { value = module.cloudflare.tunnel_token } }

  ingress      = null # アウトバウンド接続のみ
  min_replicas = 2    # SPOF 対策（コネクタ冗長化）
  max_replicas = 3
  tags         = local.common_tags
}
```

## Inputs（抜粋）

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `name` | string | - | Container App 名 |
| `resource_group_name` | string | - | リソースグループ名 |
| `container_app_environment_id` | string | - | CAE の ID |
| `revision_mode` | string | `Single` | `Single` / `Multiple` |
| `container_name` / `image` | string | - | コンテナ名 / イメージ |
| `cpu` / `memory` | number / string | `0.25` / `0.5Gi` | リソース割当 |
| `command` / `args` | list(string) | `null` | エントリポイント / 引数（例: cloudflared の `tunnel run`） |
| `env_vars` / `env_secrets` | map(string) | `{}` | 環境変数 / Secret 由来環境変数 |
| `secrets` | map(object) | `{}` | Secret（`{ value }`、インライン値） |
| `min_replicas` / `max_replicas` | number | `0` / `1` | レプリカ数（0 で scale-to-zero） |
| `custom_scale_rules` | map(object) | `{}` | KEDA カスタムスケールルール |
| `identity_type` / `identity_ids` | string / list | `SystemAssigned` / `null` | Managed Identity |
| `registry_server` / `registry_identity_id` | string | `null` | ACR と Pull 用 ID |
| `ingress` | object | `null` | Ingress 設定（`{ target_port, external_enabled?, transport?, allow_insecure_connections? }`、null で headless） |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `id` / `name` | Container App の ID / 名前 |
| `fqdn` | Ingress FQDN（内部 Ingress 時は内部 FQDN、Ingress なし時は `null`） |
| `latest_revision_name` | 最新リビジョン名 |
| `identity_principal_id` | System Assigned の Principal ID（無効時は `null`） |

## Notes

- `image` は `lifecycle.ignore_changes` 対象。初期は placeholder を置き、実イメージの更新は
  CI（`az containerapp update --image`）に任せる想定（インフラ = 構成 / CI = イメージ の分離）。
- ACR Pull は System Assigned より **User Assigned Identity** 推奨（初回デプロイ時の権限付与
  タイミング問題を回避）。`user_assigned_identity` モジュールと併用する。
