output "tunnel_id" {
  description = "The ID of the Cloudflare Tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "tunnel_token" {
  description = "Connector token. Inject into the cloudflared ACA container as TUNNEL_TOKEN (via a secret)"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.main.token
  sensitive   = true
}

output "tunnel_cname" {
  description = "CNAME target of the Tunnel (<tunnel-id>.cfargotunnel.com)"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}

output "dns_records" {
  description = "Proxied CNAMEs created by Terraform (hostname => record ID)"
  value       = { for k, r in cloudflare_dns_record.main : k => r.id }
}
