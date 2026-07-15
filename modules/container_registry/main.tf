# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags

  public_network_access_enabled = true # for access from CI/CD (GitHub Actions, etc.)

  identity {
    type = "SystemAssigned"
  }
}

# Private Endpoint (Premium SKU only; not supported on Basic/Standard)
resource "azurerm_private_endpoint" "main" {
  count               = var.private_endpoint_enabled ? 1 : 0
  name                = "pe-acr"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.app_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id_acr]
  }
}

# Diagnostic setting
resource "azurerm_monitor_diagnostic_setting" "main" {
  count                      = var.diagnostics_enabled ? 1 : 0
  name                       = "diag-acr"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
