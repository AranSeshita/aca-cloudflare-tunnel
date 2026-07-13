variable "name" {
  description = "The name of the Container App"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "container_app_environment_id" {
  description = "The ID of the Container Apps Environment to deploy into"
  type        = string
}

variable "revision_mode" {
  description = "Revision mode: Single or Multiple"
  type        = string
  default     = "Single"
}

variable "workload_profile_name" {
  description = "Workload profile name (e.g., \"Consumption\"). null for a Consumption-only environment"
  type        = string
  default     = null
}

# --- コンテナ ---
variable "container_name" {
  description = "The name of the container"
  type        = string
}

variable "image" {
  description = "Container image (e.g., acr.azurecr.io/backend:1.0.0)"
  type        = string
}

variable "cpu" {
  description = "CPU cores allocated to the container (e.g., 0.25, 0.5, 1.0)"
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory allocated to the container (e.g., 0.5Gi, 1Gi)"
  type        = string
  default     = "0.5Gi"
}

variable "command" {
  description = "Entrypoint override (container command). null leaves the image default"
  type        = list(string)
  default     = null
}

variable "args" {
  description = "Arguments passed to the container command (e.g., cloudflared tunnel run flags)"
  type        = list(string)
  default     = null
}

variable "env_vars" {
  description = "Plain environment variables (name => value)"
  type        = map(string)
  default     = {}
}

variable "env_secrets" {
  description = "Environment variables sourced from secrets (env var name => secret name)"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = <<-EOT
    アプリの Secret。secret 名 => オブジェクトのマップ:
      { value = "..." } # インライン値
  EOT
  type        = map(object({ value = string }))
  default     = {}
}

# --- スケーリング ---
variable "min_replicas" {
  description = "Minimum number of replicas (0 enables scale-to-zero)"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 1
}

variable "custom_scale_rules" {
  description = <<-EOT
    Custom (KEDA) scale rules. Map of rule name => object:
      {
        custom_rule_type = "azure-servicebus"
        metadata         = { queueName = "jobs", messageCount = "5", namespace = "sb-..." }
        authentication   = { conn = { secret_name = "sb-conn", trigger_parameter = "connection" } } # 任意
      }
  EOT
  type = map(object({
    custom_rule_type = string
    metadata         = map(string)
    authentication = optional(map(object({
      secret_name       = string
      trigger_parameter = string
    })), {})
  }))
  default = {}
}

# --- ID / レジストリ ---
variable "identity_type" {
  description = "Managed identity type: SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'"
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "User Assigned Identity IDs (required when identity_type includes UserAssigned)"
  type        = list(string)
  default     = null
}

variable "registry_server" {
  description = "Container registry login server (e.g., acr.azurecr.io). null disables the registry block"
  type        = string
  default     = null
}

variable "registry_identity_id" {
  description = "Identity used to pull from the registry ('System' or a User Assigned Identity ID)"
  type        = string
  default     = null
}

# --- Ingress（受信） ---
variable "ingress" {
  description = <<-EOT
    Ingress config, or null for headless workers (cloudflared / batch):
      { external_enabled = false, target_port = 3000, transport = "auto" }
  EOT
  type = object({
    external_enabled           = optional(bool, false)
    target_port                = number
    transport                  = optional(string, "auto")
    allow_insecure_connections = optional(bool, false)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
