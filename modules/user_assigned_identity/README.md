# user_assigned_identity

Creates a User Assigned Managed Identity (UAMI) and role assignments for it.
Used as the identity that lets ACA apps access ACR and other resources **without secrets**.

This sample creates two of them, one for the frontend and one for the backend
(distinguished by `suffix`), each granted `AcrPull`.

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

Pass to `container_app`:

```hcl
identity_type        = "UserAssigned"
identity_ids         = [module.id_frontend.id]
registry_identity_id = module.id_frontend.id
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `project_name` / `environment` | string | - | Naming prefix / environment |
| `suffix` | string | `""` | Suffix for the identity name (to distinguish multiple identities) |
| `role_assignments` | map(object) | `{}` | Map of `{ scope, role_definition_name }` |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UAMI ID (pass to `container_app`'s `identity_ids`) |
| `principal_id` | Principal ID for role assignments |
| `client_id` | Client ID used by the app to acquire Microsoft Entra ID tokens (`AZURE_CLIENT_ID`) |
| `name` | UAMI name |

## Notes

- Creating role assignments requires the executing principal to have
  `Microsoft.Authorization/roleAssignments/write` (Owner or User Access Administrator).
- For ACR pull, a UAMI is preferred over System Assigned (avoids the permission-grant
  timing issue on first deployment).
