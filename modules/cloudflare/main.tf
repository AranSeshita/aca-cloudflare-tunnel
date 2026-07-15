# The Cloudflare Tunnel itself, terminated by the `cloudflared` container running on ACA.
# config_src = "cloudflare" means the ingress routing is managed remotely on the Cloudflare side.
# With remote management, no tunnel_secret is needed (Cloudflare generates and manages it).
resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.account_id
  name       = "${var.project_name}-${var.environment}-tunnel"
  config_src = "cloudflare"
}

# Ingress routing: public hostname → internal service URL reachable from cloudflared
# (e.g. the internal FQDN of the frontend ACA). A catch-all rule is required and must be last.
# Note: in provider v5, `config` is a nested attribute, not a block.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
  source     = "cloudflare"

  config = {
    ingress = concat(
      [for r in var.ingress_rules : {
        hostname = r.hostname
        service  = r.service
        path     = r.path
        # For an https origin (e.g. an ACA FQDN inside the internal CAE), the Host header
        # and SNI must match the origin FQDN (otherwise TLS/SNI validation fails). When the
        # caller does not pass origin_request, auto-derive both from the service host.
        origin_request = r.origin_request != null ? r.origin_request : (
          startswith(r.service, "https://") ? {
            http_host_header   = replace(replace(r.service, "https://", ""), "/", "")
            origin_server_name = replace(replace(r.service, "https://", ""), "/", "")
          } : null
        )
      }],
      [{ service = var.catch_all_service }]
    )
  }
}

# Connector token, required to start cloudflared. In v5 it is fetched via a data source
# (the resource no longer exports `tunnel_token`).
data "cloudflare_zero_trust_tunnel_cloudflared_token" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

# DNS CNAMEs pointing at the Tunnel, created by Terraform. Proxied (orange cloud) so that
# CDN/WAF take effect. Rules with create_dns = false are excluded (an escape hatch when the
# existing zone is managed manually in the dashboard and a same-name CNAME would conflict;
# v5 removed allow_overwrite, so a conflict makes the apply fail).
# Note: v5 renamed `cloudflare_record` to `cloudflare_dns_record`.
# `value` was replaced by `content`, and `ttl` is required (1 = automatic).
resource "cloudflare_dns_record" "main" {
  for_each = { for r in var.ingress_rules : r.hostname => r if r.create_dns }

  zone_id = var.zone_id
  name    = each.value.hostname
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Note: the WAF (managed rulesets / custom rules / rate limiting) is deliberately NOT
# managed here. It is operated from the Cloudflare dashboard so it can be tuned instantly
# during incidents without going through a Terraform PR cycle. Managed ruleset resources
# also tend to break across provider major versions. This module only covers the Tunnel,
# its routing, and (optionally) DNS.
