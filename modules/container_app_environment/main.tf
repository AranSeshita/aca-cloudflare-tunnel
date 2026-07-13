# Container Apps Environment (CAE)
# VNet 注入 + internal 専用（Public IP なし）にして、ワークロードを完全に閉域化する。
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags

  # 委任済みの ACA サブネットへ注入する。internal_load_balancer_enabled = true にすると
  # Ingress は VNet 内からのみ到達可能になる（Internal Ingress Only）。
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled

  # 任意の Workload Profile。空の場合は Consumption-only 環境を作成する。
  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  # Consumption-only 環境では Azure が "Consumption" プロファイルを自動追加する。差分を
  # 無視して、Terraform が apply のたびに削除しようとしないようにする。
  lifecycle {
    ignore_changes = [workload_profile]
  }
}
