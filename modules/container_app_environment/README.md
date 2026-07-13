# container_app_environment

Azure Container Apps Environment (CAE) を作成するモジュール。VNet 注入 + Internal
Load Balancer により、**完全閉域（Internal Ingress Only）**の ACA 実行環境を提供する。
Public IP / Public FQDN を持たず、外部からの到達経路は Cloudflare Tunnel だけになる。

## Usage

```hcl
module "cae" {
  source = "../../modules/container_app_environment"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  project_name               = var.project_name
  environment                = local.environment
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  infrastructure_subnet_id   = module.network.subnet_ids["aca"] # Microsoft.App/environments へ委任
  tags                       = local.common_tags
}
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `resource_group_name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `project_name` | string | - | リソース名プレフィックス |
| `environment` | string | - | 環境名（dev / prod） |
| `log_analytics_workspace_id` | string | - | Log Analytics Workspace ID |
| `infrastructure_subnet_id` | string | - | ACA 注入用の委任サブネット ID |
| `internal_load_balancer_enabled` | bool | `true` | 内部 LB（閉域）にするか |
| `workload_profiles` | list(object) | `[]` | Workload Profile（空で Consumption-only） |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `id` | CAE の ID |
| `name` | CAE 名 |
| `default_domain` | 内部 FQDN 生成に使うデフォルトドメイン |
| `static_ip_address` | 環境の静的 IP（内部 LB IP） |

## Notes

- `infrastructure_subnet_id` は **`Microsoft.App/environments` へ委任**されたサブネットであること。
- サブネットサイズは Consumption-only で最小 `/23`、Workload Profile 環境で最小 `/27`。
