# This module uses a third-party provider, so (unlike the azurerm-only modules) it must
# declare it here. The consuming environment must also configure `provider "cloudflare"`
# with an API token. Resource and attribute names differ across Cloudflare provider major
# versions; this module targets v5.x. Review every resource name before upgrading to v6.
terraform {
  required_version = ">= 1.5"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.19"
    }
  }
}
