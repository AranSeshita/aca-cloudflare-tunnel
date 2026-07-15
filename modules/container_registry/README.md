# container_registry

Creates an Azure Container Registry (ACR). Supports pushes from CI and
**pulls from ACA via Managed Identity (AcrPull)**.

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

For pulls from ACA, grant `AcrPull` to the UAMI and pass the registry settings to `container_app`:

```hcl
# UAMI side
role_assignments = {
  acr_pull = { scope = module.container_registry.acr_id, role_definition_name = "AcrPull" }
}
# container_app side
registry_server      = module.container_registry.acr_login_server
registry_identity_id = module.id_frontend.id
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `project_name` / `environment` | string | - | ACR naming (`acr{project_name}{environment}`, hyphens stripped) / environment name |
| `sku` | string | `Standard` | `Basic` / `Standard` / `Premium` (Private Endpoint requires Premium) |
| `private_endpoint_enabled` | bool | `false` | Whether to create a Private Endpoint (requires Premium) |
| `app_subnet_id` | string | `null` | Subnet ID for the PE (required when PE is enabled) |
| `private_dns_zone_id_acr` | string | `null` | ACR Private DNS Zone ID (required when PE is enabled) |
| `log_analytics_workspace_id` | string | `null` | Workspace ID for diagnostic logs |
| `diagnostics_enabled` | bool | `true` | Whether to create the diagnostic setting (requires `log_analytics_workspace_id`) |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `acr_id` | ACR ID |
| `acr_name` | ACR name |
| `acr_login_server` | Login server URL |
| `principal_id` | Principal ID of the ACR managed identity |
| `private_endpoint_id` | Private Endpoint ID (`null` when PE is disabled) |

## Notes

- **Admin auth is disabled**. Access goes through the public endpoint with Managed Identity auth.
- IP/VNet restrictions and Private Endpoint are **Premium SKU only**. If a fully private
  registry is required, switch to `sku = "Premium"` + `private_endpoint_enabled = true`.
