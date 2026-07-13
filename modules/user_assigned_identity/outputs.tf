output "id" {
  description = "The ID of the User Assigned Identity (pass to container_app identity_ids)"
  value       = azurerm_user_assigned_identity.main.id
}

output "principal_id" {
  description = "The Principal (object) ID — used for role assignments"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "client_id" {
  description = "The Client ID — used by apps for AAD token acquisition (e.g., AZURE_CLIENT_ID)"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "name" {
  description = "The UAMI name — PostgreSQL の Entra プリンシパル名 / PGUSER に使う"
  value       = azurerm_user_assigned_identity.main.name
}
