terraform {
  required_version = "~> 1.0.0"
  required_providers {
    azurerm = {
      source  = "registry.terraform.io/hashicorp/azurerm"
      version = "~> 2.65.0"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.1.0"
    }
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

resource "azurerm_resource_group" "hub" {
  name     = "test-hub-rg"
  location = "eastus2"
}

resource "azurerm_resource_group" "spoke" {
  name     = "test-spoke-rg"
  location = "eastus2"
}

module "lab" {
  source = "../"

  hub_resource_group   = azurerm_resource_group.hub.name
  spoke_resource_group = azurerm_resource_group.spoke.name

  prefix = "test"
}
