# container_app_environment

Module that creates an Azure Container Apps Environment (CAE). Through VNet injection
plus an internal load balancer, it provides a **fully private (Internal Ingress Only)**,
VNet-integrated ACA runtime. It has no public IP / public FQDN, so the only inbound path
from the outside is the Cloudflare Tunnel.

## Usage

```hcl
module "cae" {
  source = "../../modules/container_app_environment"

  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.resource_group_location
  project_name               = var.project_name
  environment                = local.environment
  log_analytics_workspace_id = module.monitor.log_analytics_workspace_id
  infrastructure_subnet_id   = module.network.subnet_ids["aca"] # delegated to Microsoft.App/environments
  tags                       = local.common_tags
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|------|
| `resource_group_name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `project_name` | string | - | Resource name prefix |
| `environment` | string | - | Environment name (dev / prod) |
| `log_analytics_workspace_id` | string | - | Log Analytics Workspace ID |
| `infrastructure_subnet_id` | string | - | Delegated subnet ID for ACA injection |
| `internal_load_balancer_enabled` | bool | `true` | Use an internal LB (fully private) |
| `workload_profiles` | list(object) | `[]` | Workload profiles (empty for Consumption-only) |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|------|
| `id` | ID of the CAE |
| `name` | CAE name |
| `default_domain` | Default domain used to build internal FQDNs |
| `static_ip_address` | Static IP of the environment (internal LB IP) |

## Notes

- `infrastructure_subnet_id` must be a subnet **delegated to `Microsoft.App/environments`**.
- Minimum subnet size is `/23` for Consumption-only and `/27` for workload profile environments.
