terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.19"
    }
  }

  # state はデフォルトでローカル（このディレクトリの terraform.tfstate）。
  # 本番ではリモートバックエンドを使うこと（README の「State management」を参照）。
  # 例（Azure Blob）:
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-acatunnel-dev-state"
  #   storage_account_name = "acatunneltfstatedev"
  #   container_name       = "tfstate"
  #   key                  = "dev/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
