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

  # State is local by default (terraform.tfstate in this directory).
  # Use a remote backend for production (see "State management" in the README).
  # Example (Azure Blob):
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
