output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = azurerm_nat_gateway.main.id
}

output "public_ip_id" {
  description = "The ID of the NAT Gateway public IP"
  value       = azurerm_public_ip.nat.id
}

output "public_ip_address" {
  description = "The fixed egress IP. Use this for downstream IP allow-lists (e.g., external APIs)"
  value       = azurerm_public_ip.nat.ip_address
}
