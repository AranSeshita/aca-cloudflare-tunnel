variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_id" {
  description = "Zone ID for DNS records / WAF"
  type        = string
}

variable "project_name" {
  description = "Project name used for the Tunnel name and other identifiers"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    Tunnel routing rules: public hostname => internal service URL reachable from cloudflared.
    List elements:
      hostname       = "app.example.com"        # public hostname
      service        = "https://<internal ACA FQDN>" # origin reachable from cloudflared
      path           = "/api"                   # optional: path match
      create_dns     = true                     # optional (default true): create the proxied CNAME via Terraform
      origin_request = { ... }                  # optional: auto-derived from the https origin host when omitted (service must then be "https://<host>" with no path)
  EOT
  type = list(object({
    hostname       = string
    service        = string
    path           = optional(string)
    create_dns     = optional(bool, true)
    origin_request = optional(any)
  }))
  default = []
}

variable "catch_all_service" {
  description = "Fallback for unmatched requests (Cloudflare requires a trailing catch-all rule)"
  type        = string
  default     = "http_status:404"
}
