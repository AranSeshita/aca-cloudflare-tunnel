# CLAUDE.md

Azure Container Apps (ACA) を Cloudflare Tunnel 経由で公開するサンプル (Terraform)。
エッジ (CDN/WAF) を Cloudflare に寄せ、ACA は Internal (VNet 統合) にして **Azure 側 Inbound 開放ゼロ**。

## 構成

- `env/dev/` … ルート。**terraform はここで実行する**。
  `main.tf`(module 呼び出し) / `variables.tf` / `locals.tf` / `outputs.tf` / `provider.tf` / `terraform.tfvars.example`
- `modules/` … 再利用モジュール。新規インフラは**フラットに resource を書かず、該当 module に足す**。
  無ければ `modules/<name>/` を新設し `main.tf` / `variables.tf` / `outputs.tf`（+ README）を置く。

## 規約

- **プロバイダ**: `azurerm ~> 4.0` / `cloudflare ~> 5.19`。
  cloudflare を使う module だけ `versions.tf` で `required_providers` を宣言（azurerm 系は不要）。
- **命名**: 代表リソースは `"main"`、for_each するものは `"this"`。
  名前は `<種別>-<project_name>-<environment>`（ACR だけ英数字のみ `acr{project}{env}`）。
- **コメント・ドキュメントは日本語**で統一（製品名 / 技術用語の英語は可）。
- 各 module の README は `Usage` / `Inputs` / `Outputs` / `Notes` の統一フォーマット。
- **Key Vault は使わない**（Tunnel Token は ACA Secret にインライン格納）。
- state は既定でローカル。本番はリモートバックエンド（README「State management」参照）。

## 必須フロー（.tf を編集したら毎回）

```bash
cd env/dev
terraform fmt -recursive ../..
terraform init -backend=false -input=false
terraform validate
```

- `plan` / `apply` は Azure + Cloudflare の認証と実値が要る。**勝手に実行しない**。必要なら手順を提示して確認を取る。
