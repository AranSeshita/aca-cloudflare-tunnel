# ==========================================================================
# Outputs (root)
# ==========================================================================
output "resource_group_name" {
  description = "Resource group name."
  value       = module.resource_group.resource_group_name
}

output "acr_login_server" {
  description = "ACR login server (push app images here)."
  value       = local.acr_login_server
}

output "cae_default_domain" {
  description = "Container Apps Environment default domain (internal app FQDNs are <app>.<this>)."
  value       = module.cae.default_domain
}

output "frontend_fqdn" {
  description = "Frontend Container App internal FQDN (the tunnel origin)."
  value       = module.aca_frontend.fqdn
}

output "backend_fqdn" {
  description = "Backend Container App internal FQDN."
  value       = module.aca_backend.fqdn
}

output "nat_egress_ip" {
  description = "Fixed outbound egress IP of the ACA subnet (for downstream allow-lists)."
  value       = module.nat_gateway.public_ip_address
}

output "tunnel_id" {
  description = "Cloudflare Tunnel ID."
  value       = module.cloudflare.tunnel_id
}

output "tunnel_cname" {
  description = "Tunnel CNAME target (<tunnel-id>.cfargotunnel.com)."
  value       = module.cloudflare.tunnel_cname
}

output "dns_records" {
  description = "Proxied CNAME records created by Terraform (hostname => record ID)."
  value       = module.cloudflare.dns_records
}

output "public_url" {
  description = "Public URL served through Cloudflare (CDN/WAF + Tunnel)."
  value       = "https://${var.public_hostname}"
}
