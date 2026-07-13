# user_assigned_identity

User Assigned Managed Identity (UAMI) と、その ID へのロール割り当てを作成するモジュール。
ACA アプリが**シークレットレス**で ACR などにアクセスするための ID として使う。

このサンプルでは Frontend / Backend 用に 2 つ作り（`suffix` で区別）、それぞれに `AcrPull` を付与する。

## Usage

```hcl
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
```

`container_app` へ渡す:

```hcl
identity_type        = "UserAssigned"
identity_ids         = [module.id_frontend.id]
registry_identity_id = module.id_frontend.id
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `resource_group_name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `project_name` / `environment` | string | - | 命名プレフィックス / 環境 |
| `suffix` | string | `""` | ID 名のサフィックス（複数 ID の区別用） |
| `role_assignments` | map(object) | `{}` | `{ scope, role_definition_name }` のマップ |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `id` | UAMI の ID（`container_app` の `identity_ids` に渡す） |
| `principal_id` | ロール割り当て用の Principal ID |
| `client_id` | アプリの AAD トークン取得用（`AZURE_CLIENT_ID`） |
| `name` | UAMI 名 |

## Notes

- ロール割り当てには実行プリンシパルに `Microsoft.Authorization/roleAssignments/write`
  （Owner または User Access Administrator）が必要。
- ACR Pull は System Assigned より UAMI 推奨（初回デプロイ時の権限付与タイミング問題を回避）。
