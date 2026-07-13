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

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for the environment logs"
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "The ID of the subnet delegated to Microsoft.App/environments for ACA injection"
  type        = string
}

variable "internal_load_balancer_enabled" {
  description = "When true, ingress is internal-only (no public IP). Keep true for a fully private environment"
  type        = bool
  default     = true
}

variable "workload_profiles" {
  description = "Optional workload profiles. Empty list creates a Consumption-only environment"
  type = list(object({
    name                  = string
    workload_profile_type = string
    minimum_count         = number
    maximum_count         = number
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
