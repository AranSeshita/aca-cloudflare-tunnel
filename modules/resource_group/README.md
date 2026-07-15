# resource_group

Creates a resource group.

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

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_id` | Resource group ID |
| `resource_group_name` | Resource group name |
| `resource_group_location` | Region |

## Notes

- The full name is provided by the caller (by convention `rg-<project_name>-<environment>`);
  the module does no naming of its own.
