# monitor

Creates a Log Analytics Workspace. Used as the log destination for the Container Apps Environment.

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

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `project_name` / `environment` | string | - | Naming prefix / environment |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `log_analytics_workspace_id` | Log Analytics Workspace ID (passed to the CAE) |
| `log_analytics_workspace_name` | Workspace name |

## Notes

- The workspace is fixed to `sku = "PerGB2018"` with `retention_in_days = 30`.
  Adjust in `main.tf` if you need a different retention period.
