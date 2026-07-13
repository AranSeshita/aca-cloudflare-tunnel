# 本モジュールはサードパーティ provider を使うため、（azurerm 系モジュールと違い）ここで
# 宣言する必要がある。利用側の環境でも `provider "cloudflare"` に API トークンを設定すること。
# リソース名 / 属性名は Cloudflare provider のメジャーバージョン間で異なる。本モジュールは
# v5.x を前提とする。v6 へ上げる場合は全リソース名を見直すこと。
terraform {
  required_version = ">= 1.5"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.19"
    }
  }
}
