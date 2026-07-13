# Cloudflare Tunnel 本体。ACA 上の `cloudflared` コンテナが終端する。
# config_src = "cloudflare" にすると Ingress ルーティングを Cloudflare 側（リモート）で管理する。
# リモート管理では tunnel_secret は不要（Cloudflare 側で生成・管理される）。
resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.account_id
  name       = "${var.project_name}-${var.environment}-tunnel"
  config_src = "cloudflare"
}

# Ingress ルーティング: 公開ホスト名 → cloudflared から到達可能な内部サービス URL
#（例: Frontend ACA の内部 FQDN）。末尾に catch-all ルールが必須。
# 注意: provider v5 では `config` はブロックではなくネスト属性。
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
  source     = "cloudflare"

  config = {
    ingress = concat(
      [for r in var.ingress_rules : {
        hostname = r.hostname
        service  = r.service
        path     = r.path
        # https origin（例: 内部 CAE の ACA FQDN）では host ヘッダーと SNI を origin の
        # FQDN に合わせる必要がある（合わないと TLS/SNI 検証に失敗する）。呼び出し側が
        # origin_request を渡さない場合は service の host から自動導出する。
        origin_request = r.origin_request != null ? r.origin_request : (
          startswith(r.service, "https://") ? {
            http_host_header   = replace(replace(r.service, "https://", ""), "/", "")
            origin_server_name = replace(replace(r.service, "https://", ""), "/", "")
          } : null
        )
      }],
      [{ service = var.catch_all_service }]
    )
  }
}

# コネクタトークン。cloudflared の起動に必要。v5 では data source で取得する
#（resource 側は `tunnel_token` を出力しなくなった）。
data "cloudflare_zero_trust_tunnel_cloudflared_token" "main" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

# Tunnel 宛の DNS CNAME を Terraform で作成する。proxied（橙雲）にして CDN/WAF を効かせる。
# create_dns = false のルールは除外（既存ゾーンがダッシュボード手動管理で、同名 CNAME が
# 衝突する場合の逃げ道。v5 は allow_overwrite 廃止のため衝突すると apply が失敗する）。
# 注意: v5 で `cloudflare_record` → `cloudflare_dns_record` に改称。
# `value` は `content` に置き換わり、`ttl` は必須（1 = 自動）。
resource "cloudflare_dns_record" "main" {
  for_each = { for r in var.ingress_rules : r.hostname => r if r.create_dns }

  zone_id = var.zone_id
  name    = each.value.hostname
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# 注意: WAF（マネージドルールセット / カスタムルール / レート制限）は意図的にここで
# 管理しない。インシデント時に Terraform の PR サイクルを介さず即時チューニングできるよう
# Cloudflare ダッシュボードで運用する。マネージドルールセットのリソースは provider の
# メジャーバージョン間で壊れやすい事情もある。本モジュールは Tunnel とルーティング、
#（任意で）DNS のみを担う。
