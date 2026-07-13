# nat_gateway

NAT Gateway + 静的パブリック IP を作成し、指定サブネット（ACA サブネット）の
**アウトバウンドを単一固定 IP に集約**するモジュール。

本構成では、内部 CAE 上の `cloudflared` が Cloudflare Edge へアウトバウンド接続するための
安定した egress 経路として使う（Azure のデフォルト送信アクセス廃止に依存しない）。

## Usage

```hcl
module "nat_gateway" {
  source = "../../modules/nat_gateway"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  subnets             = { aca = module.network.subnet_ids["aca"] }
  tags                = local.common_tags
}
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `resource_group_name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `project_name` / `environment` | string | - | 命名プレフィックス / 環境 |
| `subnets` | map(string) | `{}` | 関連付けるサブネット（`{ ラベル = subnet_id }`。キーは plan 時既知であること） |
| `idle_timeout_in_minutes` | number | `4` | TCP アイドルタイムアウト |
| `zones` | list(string) | `null` | パブリック IP の AZ |
| `tags` | map(string) | `{}` | タグ |

## Outputs

| Name | 説明 |
|------|------|
| `nat_gateway_id` | NAT Gateway の ID |
| `public_ip_id` | パブリック IP の ID |
| `public_ip_address` | **固定 egress IP**（外部サービスの IP 許可リスト等に利用） |

## Notes

- NAT Gateway はゾーンリソース（ゾーン冗長ではない）。高可用性が要る場合は設計で考慮する。
- NAT が担うのは Internet 向けアウトバウンドのみ。VNet 内通信は経由しない。
