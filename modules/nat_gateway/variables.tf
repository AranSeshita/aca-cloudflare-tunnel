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

variable "subnets" {
  description = <<-EOT
    Subnets to associate with the NAT Gateway, as a map of static label => subnet ID
    (e.g., { aca = module.network.subnet_ids["aca"] }). The map KEYS must be known at plan
    time; the subnet ID VALUES may be apply-time computed values.
  EOT
  type        = map(string)
  default     = {}
}

variable "idle_timeout_in_minutes" {
  description = "TCP idle timeout in minutes (4-120)"
  type        = number
  default     = 4
}

variable "zones" {
  description = "Availability zones for the public IP (e.g., [\"1\"]). null for no zone"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
