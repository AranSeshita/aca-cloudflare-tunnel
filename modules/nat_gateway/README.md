# nat_gateway

Creates a NAT Gateway + static public IP and **funnels the outbound traffic of the given
subnets (the ACA subnet) through a single fixed IP**.

In this setup it provides a stable egress path for `cloudflared` running on the internal CAE
to reach the Cloudflare Edge (without relying on Azure default outbound access, which is
being retired).

## Usage

```hcl
module "nat_gateway" {
  source = "../../modules/nat_gateway"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  subnets             = { aca = module.network.subnet_ids["aca"] }
  tags                = local.common_tags
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `resource_group_name` | string | - | Resource group name |
| `location` | string | - | Azure region |
| `project_name` / `environment` | string | - | Naming prefix / environment |
| `subnets` | map(string) | `{}` | Subnets to associate (`{ label = subnet_id }`; keys must be known at plan time) |
| `idle_timeout_in_minutes` | number | `4` | TCP idle timeout |
| `zones` | list(string) | `null` | Availability zones for the public IP |
| `tags` | map(string) | `{}` | Tags |

## Outputs

| Name | Description |
|------|-------------|
| `nat_gateway_id` | NAT Gateway ID |
| `public_ip_id` | Public IP ID |
| `public_ip_address` | **Fixed egress IP** (use for IP allow-lists of external services, etc.) |

## Notes

- NAT Gateway is a zonal resource (not zone-redundant). Factor this in if you need high availability.
- The NAT Gateway only handles Internet-bound outbound traffic; intra-VNet traffic does not go through it.
