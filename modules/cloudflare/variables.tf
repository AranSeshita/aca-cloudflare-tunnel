variable "account_id" {
  description = "Cloudflare アカウント ID"
  type        = string
}

variable "zone_id" {
  description = "DNS レコード / WAF 対象のゾーン ID"
  type        = string
}

variable "project_name" {
  description = "Tunnel 名などに使うプロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名（dev / prod など）"
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    Tunnel のルーティング。公開ホスト名 → cloudflared から到達可能な内部サービス URL。
    リスト要素:
      hostname       = "app.example.com"       # 公開ホスト名
      service        = "https://<ACA 内部 FQDN>" # cloudflared から到達可能な origin
      path           = "/api"                   # 任意: パスマッチ
      create_dns     = true                     # 任意（既定 true）: proxied な CNAME を Terraform で作成
      origin_request = { ... }                  # 任意: 未指定なら https origin の host から自動導出
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
  description = "未マッチ時のフォールバック（Cloudflare は末尾ルールを要求する）"
  type        = string
  default     = "http_status:404"
}
