resource "random_integer" "hub" {
  min = 999
  max = 99999
  keepers = {
    rg = var.hub_resource_group
  }
}

resource "azurerm_virtual_network" "hub" {
  name                = format("%s-%s", var.prefix, "vnet")
  resource_group_name = var.hub_resource_group
  location            = var.location

  address_space = [local.networks.hub.address_space]
}

resource "azurerm_subnet" "private_management" {
  name                 = "PrivateManagement"
  resource_group_name  = var.hub_resource_group
  virtual_network_name = azurerm_virtual_network.hub.name

  address_prefixes = [cidrsubnet(local.networks.hub.address_space, 8, 0)]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.hub_resource_group
  virtual_network_name = azurerm_virtual_network.hub.name

  address_prefixes = [cidrsubnet(local.networks.hub.address_space, 10, 4)]
}

resource "azurerm_virtual_network_peering" "hub" {
  name                      = "PeerFromHubToSpoke"
  resource_group_name       = var.hub_resource_group
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = true

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

resource "azurerm_log_analytics_workspace" "hub" {
  name                = format("%s-%s-%s", var.prefix, "logging", random_integer.hub.result)
  resource_group_name = var.hub_resource_group
  location            = var.location

  sku               = "PerGB2018"
  retention_in_days = 30
}

resource "azurerm_storage_account" "hub" {
  name                = lower(format("%s%s%s", var.prefix, "storage", random_integer.hub.result))
  resource_group_name = var.hub_resource_group
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "hub_storage" {
  name                       = "hub-storage-diag-settings"
  target_resource_id         = azurerm_storage_account.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id

  metric {
    category = "Transaction"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "Capacity"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
