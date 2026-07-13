# monitor

Log Analytics Workspace を作成するモジュール。Container Apps Environment のログ出力先として使う。

## Usage

```hcl
module "monitor" {
  source = "../../modules/monitor"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  tags                = local.common_tags
}
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `resource_group_name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `project_name` / `environment` | string | - | 命名プレフィックス / 環境 |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `log_analytics_workspace_id` | Log Analytics Workspace の ID（CAE に渡す） |
| `log_analytics_workspace_name` | Workspace 名 |
