variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "The project name used as a resource name prefix"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, prod)"
  type        = string
}

variable "suffix" {
  description = "Optional name suffix to distinguish multiple identities (e.g., \"-aca\")"
  type        = string
  default     = ""
}

variable "role_assignments" {
  description = <<-EOT
    Role assignments for this identity. Map of key => object:
      { scope = "<resource id>", role_definition_name = "AcrPull" }
  EOT
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
