variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "project_name" {
  type        = string
  description = "The project name used as a resource name prefix"
}

variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space (e.g. [\"10.0.0.0/16\"])"
}

variable "subnets" {
  description = <<-EOT
    Subnets to create, keyed by logical name (e.g. "aca", "app"). Fully caller-defined
    so the module has NO hardcoded subnets — extend by editing tfvars, not the module.

    Per subnet:
      address_prefixes                  - CIDR(s) for the subnet
      private_endpoint_network_policies - "Disabled" (default) | "Enabled" | ...
      delegation                        - optional { name, actions } service delegation
      nsg_rules                         - optional map of NSG rules (key = rule name)

    Example:
      aca = {
        address_prefixes = ["10.0.0.0/23"]
        delegation = { name = "Microsoft.App/environments", actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] }
        nsg_rules = {
          AllowToInternet = { priority = 200, direction = "Outbound", access = "Allow", destination_address_prefix = "Internet" }
        }
      }
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
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
