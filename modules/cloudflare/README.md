# cloudflare

Cloudflare Tunnel + ルーティング + DNS を構成するモジュール。外部公開を
**Cloudflare 経由のアウトバウンド接続（Tunnel）**で行い、Azure 側にインバウンドを開けない。
CDN / WAF は Cloudflare 側で効かせる（WAF はダッシュボード運用。後述）。

データフロー:

```
Browser → Cloudflare (CDN / WAF) → Tunnel → cloudflared (ACA) → Frontend (ACA 内部 Ingress)
```

構成するリソース:

1. `cloudflare_zero_trust_tunnel_cloudflared` — Tunnel 本体（`config_src = "cloudflare"`）
2. `cloudflare_zero_trust_tunnel_cloudflared_config` — Ingress ルーティング（公開ホスト名 → 内部サービス URL）
3. `cloudflare_dns_record` — Tunnel への proxied CNAME を **Terraform で作成**（`create_dns = false` で除外可）

## Usage

```hcl
module "cloudflare" {
  source = "../../modules/cloudflare"

  account_id   = var.cloudflare_account_id
  zone_id      = var.cloudflare_zone_id
  project_name = var.project_name
  environment  = local.environment

  ingress_rules = [
    {
      hostname = "app.example.com"
      # Frontend ACA の内部 Ingress FQDN（module output の fqdn を使う）
      service = "https://${module.aca_frontend.fqdn}"
    }
  ]
}

# cloudflared コンテナへトークンを注入
module "aca_cloudflared" {
  source = "../../modules/container_app"
  # ...
  env_secrets = { TUNNEL_TOKEN = "tunnel-token" }
  secrets     = { tunnel-token = { value = module.cloudflare.tunnel_token } }
  ingress     = null
}
```

利用する環境（`env/<env>`）で `provider "cloudflare"` の設定が必須:

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token # Account: Cloudflare Tunnel:Edit / Zone: DNS:Edit, Zone:Read
}
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `account_id` | string | - | Cloudflare アカウント ID |
| `zone_id` | string | - | DNS / WAF 対象ゾーン ID |
| `project_name` / `environment` | string | - | 命名用 |
| `ingress_rules` | list(object) | `[]` | ルーティング（下記スキーマ） |
| `catch_all_service` | string | `http_status:404` | 未マッチ時のフォールバック |

### `ingress_rules` スキーマ

| フィールド | 型 | 既定 | 説明 |
|-----------|----|------|------|
| `hostname` | string | - | 公開ホスト名 |
| `service` | string | - | cloudflared から到達可能な origin URL |
| `path` | string | `null` | 任意: パスマッチ |
| `create_dns` | bool | `true` | proxied CNAME を Terraform で作成するか |
| `origin_request` | any | `null` | 任意: 未指定なら https origin の host から自動導出 |

## Outputs

| Name | 説明 |
|------|------|
| `tunnel_id` | Tunnel ID |
| `tunnel_token` | コネクタトークン（**sensitive**、cloudflared に注入） |
| `tunnel_cname` | `<tunnel-id>.cfargotunnel.com` |
| `dns_records` | Terraform が作成した proxied CNAME（ホスト名 => レコード ID） |

## Notes

### service / FQDN の注意

- `ingress_rules[].service` は **cloudflared から到達可能な URL**（= Frontend ACA の内部 Ingress FQDN）。
  同一 CAE 内なら内部 FQDN で解決できる。
- https origin の場合、host ヘッダー / SNI を origin FQDN に合わせる必要がある。本モジュールは
  `origin_request` 未指定時に service の host から自動導出する。

### DNS レコード

- 各 `ingress_rules` の `hostname` に対し、`<tunnel-id>.cfargotunnel.com` への **proxied CNAME を
  Terraform で作成**する（`create_dns = true` 既定）。
- 既存ゾーンが Cloudflare ダッシュボードで手動管理されていて同名 CNAME が衝突する場合は
  `create_dns = false` にする。v5 は `allow_overwrite` 廃止のため、衝突すると apply が失敗する。

### WAF はこのモジュールで管理しない（意図的）

WAF（マネージドルールセット / カスタムルール / レート制限）は Cloudflare ダッシュボードで運用する。
インシデント時に即時チューニングでき、プロバイダのメジャーバージョン差にも巻き込まれない。
proxied な DNS にしておけば WAF はゾーンレベルで自動適用される。
