output "id" {
  description = "The ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}

output "name" {
  description = "The name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "default_domain" {
  description = "The default domain of the Container Apps Environment (used to build internal app FQDNs)"
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  description = "The static IP address of the environment (internal LB IP when internal_load_balancer_enabled = true)"
  value       = azurerm_container_app_environment.main.static_ip_address
}
