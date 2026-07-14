# aca-cloudflare-tunnel

Azure Container Apps (ACA) を **Cloudflare Tunnel** 経由で公開するサンプル構成（Terraform）。

> 📝 解説記事: [Cloudflare Tunnel で 閉域内の Azure Container Apps を安全かつ低予算で公開する](https://zenn.dev/aranseshita/articles/c6062effc4e8a0)

Azure Front Door Premium（WAF 用に月 $330）を使わず、CDN / WAF を Cloudflare 側で完結させる。
ACA は Internal（VNet 統合）で構築し、外部からの到達経路は Tunnel のアウトバウンド接続だけ。
**Azure 側の Inbound 開放はゼロ**。

## 特徴

- WAF を安く — AFD Premium（$330/月）でしか使えなかった WAF を Cloudflare（Free / Pro $20）で
- Inbound ゼロ — Origin は Tunnel のアウトバウンド接続のみ。Public IP / Public FQDN なし
- 証明書レス — ACA へのカスタムドメイン登録・証明書管理が不要（Host ヘッダー書き換えで解決）
- 全部 Terraform — Portal 操作なしで再現可能

## アーキテクチャ

```
Browser
  → Cloudflare (CDN / WAF)
    → Tunnel
      → cloudflared (ACA)
        → Frontend (ACA 内部 Ingress)
          → Backend
```

- ACA Environment は Internal（Public IP / Public FQDN なし）
- `cloudflared` を ACA 上のコンテナとして常駐させ、Cloudflare Edge へアウトバウンド接続
- アウトバウンドは NAT Gateway で単一固定 IP に集約
- WAF / Geo / Rate Limit は Cloudflare ダッシュボードで運用（Terraform 管理外）

## 構成

```
env/dev/        # ルート（このディレクトリで terraform を実行）
modules/        # 再利用モジュール
├─ resource_group/
├─ network/                    # VNet + サブネット（ACA サブネットを Microsoft.App/environments へ委任）
├─ monitor/                    # Log Analytics + Application Insights
├─ container_registry/         # ACR（public + Managed Identity / AcrPull）
├─ nat_gateway/                # 固定 egress IP
├─ user_assigned_identity/     # ACA 用 UAMI + ロール付与
├─ container_app_environment/  # 内部 CAE
├─ container_app/              # 再利用コンテナアプリ（web / api / cloudflared）
└─ cloudflare/                 # Tunnel + ルーティング + DNS
```

## 前提

以下を用意しておく:

- Cloudflare で管理している独自ドメイン
- Azure サブスクリプション（MI に AcrPull を付与するため **Owner** または **Contributor + User Access Administrator**）
- Cloudflare API Token（Account: `Cloudflare Tunnel:Edit`、Zone: `DNS:Edit` / `Zone:Read`）
- Azure CLI（`az`）/ Terraform 1.5+

## 使い方

```bash
az login                                        # Azure 認証
az account set --subscription <subscription_id> # 対象サブスクリプションを選択

cd env/dev
cp terraform.tfvars.example terraform.tfvars   # 値を埋める（gitignore 済み）
terraform init
terraform plan
terraform apply
```

Cloudflare は API Token（`terraform.tfvars` の `cloudflare_api_token`）で認証するため、別途ログインは不要。

### `terraform.tfvars` に埋める値

| 変数                    | 例                | 説明                                                       |
| ----------------------- | ----------------- | ---------------------------------------------------------- |
| `subscription_id`       | `00000000-...`    | Azure サブスクリプション ID                                |
| `public_hostname`       | `app.example.com` | 公開ホスト名（`cloudflare_zone_id` のゾーン配下）          |
| `cloudflare_api_token`  | `cf-...`          | Cloudflare API Token（Tunnel:Edit / DNS:Edit / Zone:Read） |
| `cloudflare_account_id` | `...`             | Cloudflare アカウント ID                                   |
| `cloudflare_zone_id`    | `...`             | 対象ドメインの Zone ID                                     |

`project_name`（既定 `acatunnel`）/ `location`（既定 `japaneast`）は必要なら上書きする。

`apply` で、`public_hostname` の proxied CNAME（→ Tunnel）も Terraform が作成する。
反映後、`public_hostname` が Cloudflare 経由で Frontend まで到達する。

既存ゾーンをダッシュボードで手動管理していて同名 CNAME が衝突する場合は、cloudflare モジュールの
`ingress_rules[].create_dns = false` で Terraform 管理から外す。

### Deploy 後の確認（疎通確認）

デプロイされるアプリ:

|          | イメージ                                                      | ポート | 役割                                                           |
| -------- | ------------------------------------------------------------- | ------ | -------------------------------------------------------------- |
| Frontend | `joechen0713/containerapp_networktester:1.0`                  | 8080   | Tunnel 公開。診断 UI から backend の内部 FQDN を叩いて疎通確認 |
| Backend  | `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest` | 80     | 閉域内の応答役                                                 |

- Frontend は **Network Tester**（`joechen0713/containerapp_networktester`）。`public_hostname` を開くと
  診断 UI が出る＝ **Browser → Cloudflare → Tunnel → cloudflared → Frontend** の経路が通っている証拠。
- UI から **Backend の内部 FQDN**（`terraform output backend_fqdn`、Frontend には `BACKEND_URL` として注入済み）を
  叩くと、閉域内の **ACA → ACA** 疎通を確認できる。Backend は helloworld（80番）の単純な応答役。
- 実アプリに置き換えるときは `frontend_image` / `backend_image` を差し替え、Backend の
  `target_port` を実待受ポートに合わせる。

## State management

デフォルトは **ローカル state**（`env/dev/terraform.tfstate`）。手元検証はこれで十分。

**本番利用では必ずリモート state を使うこと。** state には接続情報や生成値が含まれ、ローカル
運用ではチーム共有・排他ロック・履歴が担保できない。推奨バックエンド:

- Azure Blob Storage（`backend "azurerm"`） — Storage Account + Blob コンテナを別途作成し、
  [env/dev/provider.tf](env/dev/provider.tf) のコメントアウト済み `backend "azurerm"` ブロックを
  有効化する。ロックは Blob Lease で自動。
- Terraform Cloud / HCP Terraform（`cloud {}` ブロック） — リモート実行・state 管理・ロックを
  マネージドで提供。

いずれも保管先は暗号化 + アクセス制限すること。

## コスト感

|        | AFD Premium | 本構成                                               |
| ------ | ----------- | ---------------------------------------------------- |
| WAF    | 含む        | Cloudflare（Free / Pro $20）                         |
| 固定費 | $330/月     | Cloudflare プラン + cloudflared 実行コスト（数ドル） |

OWASP Core Ruleset / Rate Limiting / 本格的な Bot 対策を使うなら Cloudflare Pro 以上。
