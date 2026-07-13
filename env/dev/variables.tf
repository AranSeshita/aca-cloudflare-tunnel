# ==========================================================================
# 入力変数（ルート）
# ==========================================================================

# --- Azure ----------------------------------------------------------------
variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "project_name" {
  description = "Short project name used to compose resource names."
  type        = string
  default     = "acatunnel"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "japaneast"
}

variable "vnet_address_space" {
  description = "VNet address space."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = <<-EOT
    Subnets for the network module, keyed by logical name. The "aca" subnet is
    delegated to Microsoft.App/environments and must be /23 or larger for a
    Consumption-only Container Apps Environment.
  EOT
  type = map(object({
    address_prefixes                  = list(string)
    private_endpoint_network_policies = optional(string, "Disabled")
    delegation = optional(object({
      name    = string
      actions = list(string)
    }))
    nsg_rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = optional(string, "*")
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), {})
  }))
  default = {
    aca = {
      address_prefixes = ["10.0.0.0/23"]
      delegation = {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

variable "frontend_image" {
  description = "Frontend のイメージ。既定は Network Tester（Tunnel 経由で開き、backend の内部 FQDN へ疎通確認する UI。8080 待受）。"
  type        = string
  default     = "docker.io/joechen0713/containerapp_networktester:1.0"
}

variable "backend_image" {
  description = "Backend のイメージ。既定は containerapps-helloworld（疎通先の応答役。80 待受・PORT を読まない）。"
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "cloudflared_image" {
  description = "cloudflared image (public Docker Hub). Pin the version; never use latest."
  type        = string
  default     = "docker.io/cloudflare/cloudflared:2026.5.0"
}

variable "public_hostname" {
  description = "Public hostname exposed via the Cloudflare Tunnel (e.g. app.example.com)."
  type        = string
}

variable "app_storage_env" {
  description = "Extra environment variables merged into the backend app (e.g. storage connection settings)."
  type        = map(string)
  default     = {}
}

# --- Cloudflare -----------------------------------------------------------
variable "cloudflare_api_token" {
  description = "Cloudflare API token (Account: Cloudflare Tunnel:Edit, Zone: DNS:Edit, Zone:Read)."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain that owns public_hostname."
  type        = string
}
