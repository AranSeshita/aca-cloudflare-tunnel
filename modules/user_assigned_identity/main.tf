# User Assigned Managed Identity（UAMI）
# ACA アプリ用の ID。認証情報を持たずに ACR pull などへアクセスするために使う。
resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.project_name}-${var.environment}${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# この ID に付与するロール割り当て（対象スコープ単位・最小権限）。
resource "azurerm_role_assignment" "main" {
  for_each             = var.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.main.principal_id
}
