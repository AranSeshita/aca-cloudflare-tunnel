# User Assigned Managed Identity (UAMI)
# Identity for ACA apps. Used to access ACR (pull) and other resources without holding credentials.
resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.project_name}-${var.environment}${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Role assignments granted to this identity (per target scope, least privilege).
resource "azurerm_role_assignment" "main" {
  for_each             = var.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}
