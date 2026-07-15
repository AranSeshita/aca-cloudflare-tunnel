# Container App (reusable)
# Instantiated once per app (cloudflared / frontend / backend, etc.).
resource "azurerm_container_app" "main" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = var.revision_mode
  workload_profile_name        = var.workload_profile_name
  tags                         = var.tags

  # In a Consumption-only environment, Azure auto-assigns "Consumption". Ignore the diff
  # so Terraform does not try to reset it to null on every run.
  #
  # The image is updated to the real ACR image by CI (`az containerapp update --image`),
  # i.e. app deployment is CI's responsibility. Terraform holds the initial placeholder
  # value, but ignores the image so it never rolls a CI-deployed image back to the
  # placeholder (infrastructure = configuration / CI = images).
  lifecycle {
    ignore_changes = [
      workload_profile_name,
      template[0].container[0].image,
    ]
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_ids
  }

  # Pull from ACR with a Managed Identity (no admin credentials).
  dynamic "registry" {
    for_each = var.registry_server == null ? [] : [1]
    content {
      server   = var.registry_server
      identity = var.registry_identity_id
    }
  }

  # Secrets (inline values).
  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.key
      value = secret.value.value
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name    = var.container_name
      image   = var.image
      cpu     = var.cpu
      memory  = var.memory
      command = var.command
      args    = var.args

      # Plain environment variables
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret-backed environment variables (env var name => secret name)
      dynamic "env" {
        for_each = var.env_secrets
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }

    # Custom scale rules (e.g. queue-length scaling via KEDA azure-servicebus)
    dynamic "custom_scale_rule" {
      for_each = var.custom_scale_rules
      content {
        name             = custom_scale_rule.key
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }
  }

  # Ingress. Omitted entirely for headless workers (e.g. cloudflared).
  dynamic "ingress" {
    for_each = var.ingress == null ? [] : [var.ingress]
    content {
      external_enabled           = ingress.value.external_enabled
      target_port                = ingress.value.target_port
      transport                  = ingress.value.transport
      allow_insecure_connections = ingress.value.allow_insecure_connections

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }
}
