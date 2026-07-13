# network

VNet と、**データ駆動なサブネット**（+ サブネットごとの NSG / ルール）を作成するモジュール。
モジュール内にサブネットをハードコードせず、追加・変更は呼び出し側（tfvars）の `subnets` を編集するだけ。

このサンプルでは `Microsoft.App/environments` へ委任した `aca` サブネットを 1 つだけ作る。

## Usage

```hcl
module "network" {
  source = "../../modules/network"

  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  project_name        = var.project_name
  environment         = local.environment
  vnet_address_space  = ["10.0.0.0/16"]
  subnets             = var.subnets # tfvars で定義
  tags                = local.common_tags
}
```

`subnets` の例（tfvars）:

```hcl
subnets = {
  aca = {
    address_prefixes = ["10.0.0.0/23"] # Consumption-only CAE は /23 以上
    delegation = {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
```

## Inputs

| Name | Type | Default | 説明 |
|------|------|---------|------|
| `resource_group_name` | string | - | リソースグループ名 |
| `location` | string | - | Azure リージョン |
| `project_name` / `environment` | string | - | 命名プレフィックス / 環境 |
| `vnet_address_space` | list(string) | - | VNet CIDR |
| `subnets` | map(object) | - | サブネット定義（下記スキーマ） |
| `tags` | map(string) | `{}` | タグ |

### `subnets` スキーマ（キー = サブネット論理名）

| フィールド | 型 | 既定 | 説明 |
|-----------|----|------|------|
| `address_prefixes` | list(string) | - | サブネット CIDR |
| `private_endpoint_network_policies` | string | `"Disabled"` | PE サブネットで NSG を効かせるなら `"Enabled"` |
| `delegation` | object | `null` | `{ name, actions }` サービス委任 |
| `nsg_rules` | map(object) | `{}` | NSG ルール（キー = ルール名）。`priority/direction/access` 必須、`protocol/ports/prefixes` は既定 `*` |

## Outputs

| Name | 説明 |
|------|------|
| `vnet_id` / `vnet_name` | VNet の ID / 名前 |
| `subnet_ids` | `{ 論理名 => subnet ID }` のマップ（例: `module.network.subnet_ids["aca"]`） |

## Notes

- NSG ルールは `"<subnet>.<rule>"` キーで flatten する。キーは tfvars から静的に決まるため
  `for_each` が plan 時に確定する（apply 時の unknown key を避ける設計）。
