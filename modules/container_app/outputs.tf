output "id" {
  description = "The ID of the Container App"
  value       = azurerm_container_app.main.id
}

output "name" {
  description = "The name of the Container App"
  value       = azurerm_container_app.main.name
}

output "fqdn" {
  description = "The ingress FQDN of the Container App (internal FQDN when external_enabled = false). null when no ingress"
  value       = try(azurerm_container_app.main.ingress[0].fqdn, null)
}

output "latest_revision_name" {
  description = "The name of the latest revision"
  value       = azurerm_container_app.main.latest_revision_name
}

output "identity_principal_id" {
  description = "The System Assigned identity principal ID (null when SystemAssigned is not enabled)"
  value       = try(azurerm_container_app.main.identity[0].principal_id, null)
}
