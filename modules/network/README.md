# network

Creates a VNet and **data-driven subnets** (plus a per-subnet NSG / rules).
No subnets are hardcoded inside the module — adding or changing subnets is just a matter
of editing `subnets` on the caller side (tfvars).

In this sample, only one subnet is created: an `aca` subnet delegated to `Microsoft.App/environments`.

## Usage

```hcl
module "network" {
  source = "../../modules/network"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  vnet_address_space  = ["10.0.0.0/16"]
  subnets             = var.subnets # defined in tfvars
  tags                = local.common_tags
}
```

Example `subnets` (tfvars):

```hcl
subnets = {
  aca = {
    address_prefixes = ["10.0.0.0/23"] # Consumption-only CAE requires /23 or larger
    delegation = {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `project_name` / `environment` | string | - | Naming prefix / environment |
| `vnet_address_space` | list(string) | - | VNet CIDR |
| `subnets` | map(object) | - | Subnet definitions (schema below) |
| `tags` | map(string) | `{}` | Tags |

### `subnets` schema (key = subnet logical name)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `address_prefixes` | list(string) | - | Subnet CIDR(s) |
| `private_endpoint_network_policies` | string | `"Disabled"` | Set `"Enabled"` to enforce NSGs on a PE subnet |
| `delegation` | object | `null` | `{ name, actions }` service delegation |
| `nsg_rules` | map(object) | `{}` | NSG rules (key = rule name). `priority/direction/access` required; `protocol/ports/prefixes` default to `*` |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` / `vnet_name` | VNet ID / name |
| `subnet_ids` | Map of `{ logical name => subnet ID }` (e.g. `module.network.subnet_ids["aca"]`) |

## Notes

- NSG rules are flattened into a single map keyed by `"<subnet>.<rule>"`. The keys are
  statically derived from tfvars, so `for_each` is resolvable at plan time (avoiding
  unknown-key-at-apply issues by design).
