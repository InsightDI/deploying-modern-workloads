terraform {
  required_version = "~> 1.0"
  required_providers {
    azurerm = {
      source  = "registry.terraform.io/hashicorp/azurerm"
      version = "~> 2.65"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  skip_provider_registration = false
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = false
    }
  }
}
