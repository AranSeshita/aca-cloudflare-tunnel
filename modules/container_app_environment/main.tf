# Container Apps Environment (CAE)
# VNet injection + internal-only (no public IP) keeps the workloads fully private.
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags

  # Inject into the delegated ACA subnet. With internal_load_balancer_enabled = true,
  # ingress is reachable only from within the VNet (Internal Ingress Only).
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled

  # Optional workload profiles. An empty list creates a Consumption-only environment.
  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  # In a Consumption-only environment, Azure auto-adds a "Consumption" profile. Ignore
  # the diff so Terraform does not try to remove it on every apply.
  lifecycle {
    ignore_changes = [workload_profile]
  }
}
