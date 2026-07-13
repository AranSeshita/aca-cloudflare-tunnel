output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map of subnet logical name => subnet ID (e.g. subnet_ids[\"aca\"])"
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}
