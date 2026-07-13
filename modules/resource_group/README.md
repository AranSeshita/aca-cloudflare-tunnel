# resource_group

リソースグループを作成するモジュール。

## Usage

```hcl
module "resource_group" {
  source = "../../modules/resource_group"

  name     = "rg-${var.project_name}-${local.environment}"
  location = var.location
  tags     = local.common_tags
}
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `resource_group_id` | リソースグループの ID |
| `resource_group_name` | リソースグループ名 |
| `resource_group_location` | リージョン |
