# aca-cloudflare-tunnel

Sample Terraform configuration that exposes Azure Container Apps (ACA) through a **Cloudflare Tunnel**.

> 📝 Companion article (Japanese): [Cloudflare Tunnel で 閉域内の Azure Container Apps を安全かつ低予算で公開する](https://zenn.dev/aranseshita/articles/c6062effc4e8a0)

Instead of Azure Front Door Premium ($330/month just for WAF), CDN / WAF are handled entirely on the Cloudflare side.
ACA runs as an Internal (VNet-integrated) environment, and the only inbound path is the Tunnel's outbound-only connections.
**Zero inbound ports open on Azure.**

## Highlights

- Affordable WAF — get WAF on Cloudflare (Free / Pro $20) instead of AFD Premium ($330/month)
- Zero inbound — the origin is reachable only via outbound-only Tunnel connections. No public IP / public FQDN
- Certificate-free — no custom domain registration or certificate management on ACA (solved by Host header rewrite)
- 100% Terraform — fully reproducible, no Portal clicking

## Architecture

![Architecture diagram: a user's HTTPS request passes through Cloudflare Edge (DDoS mitigation, custom rules, rate limiting, bot protection, WAF managed rules), then through Cloudflare Tunnel into an internal ACA Environment, where cloudflared forwards it to the frontend Container App, which calls the backend internally](assets/architecture.png)

- The ACA Environment is Internal (no public IP / public FQDN)
- `cloudflared` runs as a container on ACA and maintains outbound connections to the Cloudflare edge
- Outbound traffic is consolidated to a single static IP via NAT Gateway
- WAF / Geo / Rate Limiting are managed in the Cloudflare dashboard (outside Terraform)

## Layout

```
env/dev/        # Root module (run terraform from this directory)
modules/        # Reusable modules
├─ resource_group/
├─ network/                    # VNet + subnets (ACA subnet delegated to Microsoft.App/environments)
├─ monitor/                    # Log Analytics + Application Insights
├─ container_registry/         # ACR (public + Managed Identity / AcrPull)
├─ nat_gateway/                # Static egress IP
├─ user_assigned_identity/     # UAMI for ACA + role assignments
├─ container_app_environment/  # Internal CAE
├─ container_app/              # Reusable container app (web / api / cloudflared)
└─ cloudflare/                 # Tunnel + routing + DNS
```

## Prerequisites

You will need:

- A custom domain managed on Cloudflare
- An Azure subscription (**Owner**, or **Contributor + User Access Administrator**, to grant AcrPull to the managed identities)
- A Cloudflare API Token (Account: `Cloudflare Tunnel:Edit`, Zone: `DNS:Edit` / `Zone:Read`)
- Azure CLI (`az`) / Terraform 1.5+

## Usage

```bash
az login                                        # Authenticate with Azure
az account set --subscription <subscription_id> # Select the target subscription

cd env/dev
cp terraform.tfvars.example terraform.tfvars   # Fill in the values (gitignored)
terraform init
terraform plan
terraform apply
```

Cloudflare is authenticated via API Token (`cloudflare_api_token` in `terraform.tfvars`), so no separate login is required.

### Values to fill in `terraform.tfvars`

| Variable                | Example           | Description                                                     |
| ----------------------- | ----------------- | --------------------------------------------------------------- |
| `subscription_id`       | `00000000-...`    | Azure subscription ID                                           |
| `public_hostname`       | `app.example.com` | Public hostname (must live in the `cloudflare_zone_id` zone)    |
| `cloudflare_api_token`  | `cf-...`          | Cloudflare API Token (Tunnel:Edit / DNS:Edit / Zone:Read)       |
| `cloudflare_account_id` | `...`             | Cloudflare account ID                                           |
| `cloudflare_zone_id`    | `...`             | Zone ID of the target domain                                    |

Override `project_name` (default `acatunnel`) / `location` (default `japaneast`) if needed.

On `apply`, Terraform also creates the proxied CNAME for `public_hostname` (pointing at the Tunnel).
Once it propagates, `public_hostname` reaches the Frontend through Cloudflare.

If you manage the zone manually in the dashboard and a CNAME with the same name would conflict,
set `ingress_rules[].create_dns = false` in the cloudflare module to keep it out of Terraform.

### Post-deploy verification (connectivity check)

Deployed apps:

|          | Image                                                          | Port | Role                                                                          |
| -------- | -------------------------------------------------------------- | ---- | ----------------------------------------------------------------------------- |
| Frontend | `joechen0713/containerapp_networktester:1.0`                   | 8080 | Exposed via the Tunnel. Diagnostic UI to probe the backend's internal FQDN     |
| Backend  | `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest`  | 80   | Simple responder inside the private network                                   |

- The Frontend is **Network Tester** (`joechen0713/containerapp_networktester`). If the diagnostic UI
  loads when you open `public_hostname`, the **Browser → Cloudflare → Tunnel → cloudflared → Frontend** path is working.
- From the UI, hit the **Backend's internal FQDN** (`terraform output backend_fqdn`, already injected into the
  Frontend as `BACKEND_URL`) to verify **ACA → ACA** connectivity inside the private network.
  The Backend is a plain helloworld responder (port 80).
- To swap in your real apps, replace `frontend_image` / `backend_image` and set the Backend's
  `target_port` to the actual listening port.

## State management

The default is **local state** (`env/dev/terraform.tfstate`), which is fine for local experimentation.

**Always use remote state for production.** State contains connection info and generated values,
and local state cannot provide team sharing, locking, or history. Recommended backends:

- Azure Blob Storage (`backend "azurerm"`) — create a Storage Account + Blob container, then enable
  the commented-out `backend "azurerm"` block in [env/dev/provider.tf](env/dev/provider.tf).
  Locking is handled automatically via Blob Lease.
- Terraform Cloud / HCP Terraform (`cloud {}` block) — managed remote execution, state, and locking.

Either way, keep the state store encrypted and access-restricted.

## Cost comparison

|            | AFD Premium | This setup                                             |
| ---------- | ----------- | ------------------------------------------------------ |
| WAF        | Included    | Cloudflare (Free / Pro $20)                            |
| Fixed cost | $330/month  | Cloudflare plan + cloudflared runtime cost (a few $)   |

For OWASP Core Ruleset, Rate Limiting, or serious bot protection, use Cloudflare Pro or above.
