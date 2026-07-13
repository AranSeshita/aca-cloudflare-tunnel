# container_registry

Azure Container Registry (ACR) を作成するモジュール。CI からの push と、
ACA からの **Managed Identity（AcrPull）による pull** に対応する。

## Usage

```hcl
module "container_registry" {
  source = "../../modules/container_registry"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  project_name               = var.project_name
  environment                = local.environment
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  tags                       = local.common_tags
}
```

ACA からの pull は、UAMI に `AcrPull` を付与し `container_app` に registry 設定を渡す:

```hcl
# UAMI 側
role_assignments = {
  acr_pull = { scope = module.container_registry.acr_id, role_definition_name = "AcrPull" }
}
# container_app 側
registry_server      = module.container_registry.acr_login_server
registry_identity_id = module.id_frontend.id
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `resource_group_name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `project_name` | string | - | ACR 命名用（`acr{project_name}{environment}`、ハイフン除去） |
| `environment` | string | - | 環境名（dev / stg / prod） |
| `sku` | string | `Standard` | `Basic` / `Standard` / `Premium`（PE は Premium 必須） |
| `private_endpoint_enabled` | bool | `false` | Private Endpoint を作成するか（Premium 必須） |
| `app_subnet_id` | string | `null` | PE 用サブネット ID（PE 有効時に必須） |
| `private_dns_zone_id_acr` | string | `null` | ACR Private DNS Zone ID（PE 有効時に必須） |
| `log_analytics_workspace_id` | string | `null` | 診断ログ用 Workspace ID |
| `diagnostics_enabled` | bool | `true` | 診断設定を作成するか |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `acr_id` | ACR の ID |
| `acr_name` | ACR 名 |
| `acr_login_server` | ログインサーバ URL |
| `principal_id` | ACR Managed Identity の Principal ID |
| `private_endpoint_id` | Private Endpoint の ID（PE 無効時は `null`） |

## Notes

- **Admin 認証は無効**。public エンドポイント + Managed Identity 認証で利用する。
- IP/VNet 制限や Private Endpoint は **Premium SKU 専用**。閉域化が必須なら
  `sku = "Premium"` + `private_endpoint_enabled = true` に切り替える。
