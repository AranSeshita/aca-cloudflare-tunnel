# Container App（再利用可能）
# 1 アプリ = 1 呼び出しでインスタンス化する（cloudflared / frontend / backend など）。
resource "azurerm_container_app" "main" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = var.revision_mode
  workload_profile_name        = var.workload_profile_name
  tags                         = var.tags

  # Consumption-only 環境では Azure が "Consumption" を自動付与する。差分を無視して
  # Terraform が毎回 null に戻そうとしないようにする。
  #
  # image は CI（`az containerapp update --image`）が ACR の実イメージへ更新する＝アプリの
  # デプロイ責務は CI 側。Terraform は初期の placeholder 値を持つが、CI が更新した image を
  # 毎回 placeholder へ巻き戻さないよう無視する（インフラ=構成 / CI=イメージ の分離）。
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

  # Managed Identity で ACR から pull する（admin 認証情報は使わない）。
  dynamic "registry" {
    for_each = var.registry_server == null ? [] : [1]
    content {
      server   = var.registry_server
      identity = var.registry_identity_id
    }
  }

  # Secret（インライン値）。
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

      # 通常の環境変数
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret 由来の環境変数（環境変数名 => secret 名）
      dynamic "env" {
        for_each = var.env_secrets
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }

    # カスタムスケールルール（例: KEDA azure-servicebus によるキュー長スケール）
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

  # Ingress。headless なワーカー（cloudflared など）では丸ごと省略する。
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
