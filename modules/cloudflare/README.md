# cloudflare

Module that provisions the Cloudflare Tunnel, its routing, and DNS. Public exposure happens
through **outbound-only Tunnel connections via Cloudflare**, with zero inbound ports open on Azure.
CDN / WAF are enforced on the Cloudflare side (the WAF is dashboard-managed; see below).

Data flow:

```
Browser → Cloudflare (CDN / WAF) → Tunnel → cloudflared (ACA) → Frontend (ACA internal ingress)
```

Resources managed:

1. `cloudflare_zero_trust_tunnel_cloudflared` — the Tunnel itself (`config_src = "cloudflare"`)
2. `cloudflare_zero_trust_tunnel_cloudflared_config` — ingress routing (public hostname → internal service URL)
3. `cloudflare_dns_record` — proxied CNAME to the Tunnel, **created by Terraform** (opt out with `create_dns = false`)

## Usage

```hcl
module "cloudflare" {
  source = "../../modules/cloudflare"

  account_id   = var.cloudflare_account_id
  zone_id      = var.cloudflare_zone_id
  project_name = var.project_name
  environment  = local.environment

  ingress_rules = [
    {
      hostname = "app.example.com"
      # Internal ingress FQDN of the frontend ACA (use the module's fqdn output)
      service = "https://${module.aca_frontend.fqdn}"
    }
  ]
}

# Inject the token into the cloudflared container
module "aca_cloudflared" {
  source = "../../modules/container_app"
  # ...
  env_secrets = { TUNNEL_TOKEN = "tunnel-token" }
  secrets     = { tunnel-token = { value = module.cloudflare.tunnel_token } }
  ingress     = null
}
```

The consuming environment (`env/<env>`) must configure the `provider "cloudflare"` block:

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token # Account: Cloudflare Tunnel:Edit / Zone: DNS:Edit, Zone:Read
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|------|
| `account_id` | string | - | Cloudflare account ID |
| `zone_id` | string | - | Zone ID for DNS / WAF |
| `project_name` / `environment` | string | - | Used for naming |
| `ingress_rules` | list(object) | `[]` | Routing rules (schema below) |
| `catch_all_service` | string | `http_status:404` | Fallback for unmatched requests |

### `ingress_rules` schema

| Field | Type | Default | Description |
|-----------|----|------|------|
| `hostname` | string | - | Public hostname |
| `service` | string | - | Origin URL reachable from cloudflared |
| `path` | string | `null` | Optional: path match |
| `create_dns` | bool | `true` | Whether Terraform creates the proxied CNAME |
| `origin_request` | any | `null` | Optional: auto-derived from the https origin host when omitted (assumes `service` is `https://<host>` with no path) |

## Outputs

| Name | Description |
|------|------|
| `tunnel_id` | Tunnel ID |
| `tunnel_token` | Connector token (**sensitive**, injected into cloudflared) |
| `tunnel_cname` | `<tunnel-id>.cfargotunnel.com` |
| `dns_records` | Proxied CNAMEs created by Terraform (hostname => record ID) |

## Notes

### service / FQDN caveats

- `ingress_rules[].service` must be a **URL reachable from cloudflared** (in this sample, the
  internal ingress FQDN of the frontend ACA). Within the same CAE, the internal FQDN resolves as-is.
- For an https origin, the Host header and SNI must match the origin FQDN. When
  `origin_request` is omitted, this module auto-derives both from the service host
  (this assumes `service` is `https://<host>` with no path — pass `origin_request`
  explicitly otherwise).

### DNS records

- For each `ingress_rules` `hostname`, a **proxied CNAME to `<tunnel-id>.cfargotunnel.com`
  is created by Terraform** (`create_dns = true` by default).
- If the existing zone is managed manually in the Cloudflare dashboard and a CNAME with the
  same name would conflict, set `create_dns = false`. Provider v5 removed `allow_overwrite`,
  so a conflict makes the apply fail.

### The WAF is not managed by this module (deliberately)

The WAF (managed rulesets / custom rules / rate limiting) is operated from the Cloudflare
dashboard. That allows instant tuning during incidents and keeps you out of provider
major-version breakage. As long as the DNS records are proxied, the WAF applies automatically
at the zone level.
