variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project name for ACR naming (e.g., 'myproject' becomes 'acrmyproject')"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, stg, prod)"
  type        = string
}

variable "sku" {
  description = "ACR SKU: Basic, Standard, or Premium. NOTE: Private Endpoint requires Premium"
  type        = string
  default     = "Standard"
}

variable "private_endpoint_enabled" {
  description = "Whether to create the Private Endpoint (requires Premium SKU). Default false — ACR is reached over its public endpoint with Managed Identity / token auth. Must be known at plan time"
  type        = bool
  default     = false
}

variable "app_subnet_id" {
  description = "The ID of the App subnet for Private Endpoint (required when private_endpoint_enabled = true)"
  type        = string
  default     = null
}

variable "private_dns_zone_id_acr" {
  description = "The ID of the ACR Private DNS Zone (required when private_endpoint_enabled = true)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics (required when diagnostics_enabled = true)"
  type        = string
  default     = null
}

variable "diagnostics_enabled" {
  description = "Whether to create the diagnostic setting. Must be known at plan time. Requires log_analytics_workspace_id"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
