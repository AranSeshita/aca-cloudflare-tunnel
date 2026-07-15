# container_app

Reusable Azure Container App module: one app per module call.
In this sample, all three apps — **web / api / cloudflared** — are built with this module.

- Single container + environment variables / secrets (inline values)
- ACR pull via Managed Identity (System / User Assigned)
- Switchable between ingress-enabled (internal) and headless (no ingress)
- Supports KEDA custom scale rules and scale-to-zero (`min_replicas = 0`)

## Usage

### Frontend / Backend (internal ingress)

```hcl
module "aca_frontend" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-web"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id

  container_name = "web"
  image          = "${module.container_registry.acr_login_server}/frontend:1.0.0"
  cpu            = 0.5
  memory         = "1Gi"

  identity_type        = "UserAssigned"
  identity_ids         = [module.id_frontend.id]
  registry_server      = module.container_registry.acr_login_server
  registry_identity_id = module.id_frontend.id

  ingress      = { external_enabled = false, target_port = 8080 }
  min_replicas = 1
  max_replicas = 3
  tags         = local.common_tags
}
```

### Cloudflared (headless / no ingress)

```hcl
module "aca_cloudflared" {
  source = "../../modules/container_app"

  name                         = "ca-${var.project_name}-${local.environment}-cfd"
  resource_group_name          = module.resource_group.resource_group_name
  container_app_environment_id = module.cae.id

  container_name = "cloudflared"
  image          = "docker.io/cloudflare/cloudflared:2026.5.0"
  args           = ["tunnel", "--no-autoupdate", "run", "--token", "$(TUNNEL_TOKEN)"]

  identity_type = "SystemAssigned"
  env_secrets   = { TUNNEL_TOKEN = "tunnel-token" }
  secrets       = { tunnel-token = { value = module.cloudflare.tunnel_token } }

  ingress      = null # outbound-only Tunnel connections
  min_replicas = 2    # avoid a SPOF (redundant connectors)
  max_replicas = 3
  tags         = local.common_tags
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|------|
| `name` | string | - | Container App name |
| `resource_group_name` | string | - | Resource group name |
| `container_app_environment_id` | string | - | ID of the CAE |
| `workload_profile_name` | string | `null` | Workload profile (`null` for Consumption-only) |
| `revision_mode` | string | `Single` | `Single` / `Multiple` |
| `container_name` / `image` | string | - | Container name / image |
| `cpu` / `memory` | number / string | `0.25` / `0.5Gi` | Resource allocation |
| `command` / `args` | list(string) | `null` | Entrypoint / arguments (e.g. cloudflared's `tunnel run`) |
| `env_vars` / `env_secrets` | map(string) | `{}` | Environment variables / secret-backed environment variables |
| `secrets` | map(object) | `{}` | Secrets (`{ value }`, inline values) |
| `min_replicas` / `max_replicas` | number | `0` / `1` | Replica counts (0 enables scale-to-zero) |
| `custom_scale_rules` | map(object) | `{}` | KEDA custom scale rules |
| `identity_type` / `identity_ids` | string / list | `SystemAssigned` / `null` | Managed Identity |
| `registry_server` / `registry_identity_id` | string | `null` | ACR and the identity used to pull |
| `ingress` | object | `null` | Ingress config (`{ target_port, external_enabled?, transport?, allow_insecure_connections? }`; null for headless) |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|------|
| `id` / `name` | Container App ID / name |
| `fqdn` | Ingress FQDN (internal FQDN with internal ingress; `null` when there is no ingress) |
| `latest_revision_name` | Name of the latest revision |
| `identity_principal_id` | System Assigned principal ID (`null` when disabled) |

## Notes

- `image` is covered by `lifecycle.ignore_changes`. The intended flow is to seed a placeholder
  image and let CI update it to the real image (`az containerapp update --image`) —
  infrastructure = configuration / CI = images.
- For ACR pull, a **User Assigned Identity** is preferred over System Assigned (it avoids the
  role-assignment timing problem on first deploy). Use it together with the
  `user_assigned_identity` module.
