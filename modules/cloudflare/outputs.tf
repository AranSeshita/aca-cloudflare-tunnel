output "tunnel_id" {
  description = "Cloudflare Tunnel の ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

output "tunnel_token" {
  description = "コネクタトークン。cloudflared の ACA コンテナへ TUNNEL_TOKEN（Secret 経由）で注入する"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.main.token
  sensitive   = true
}

output "tunnel_cname" {
  description = "Tunnel の CNAME ターゲット（<tunnel-id>.cfargotunnel.com）"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
}

output "dns_records" {
  description = "Terraform が作成した proxied CNAME（ホスト名 => レコード ID）"
  value       = { for k, r in cloudflare_dns_record.main : k => r.id }
}
