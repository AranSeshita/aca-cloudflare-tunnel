output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "The login server URL of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "principal_id" {
  description = "The Principal ID of the ACR managed identity"
  value       = azurerm_container_registry.main.identity[0].principal_id
}

output "private_endpoint_id" {
  description = "The ID of the Private Endpoint (null when private_endpoint_enabled = false)"
  value       = try(azurerm_private_endpoint.main[0].id, null)
}
