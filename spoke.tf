resource "random_integer" "spoke" {
  min = 999
  max = 99999
  keepers = {
    rg = var.spoke_resource_group
  }
}

resource "azurerm_virtual_network" "spoke" {
  name                = format("%s-%s", var.prefix, "vnet")
  resource_group_name = var.spoke_resource_group
  location            = var.location

  address_space = [local.networks.spoke.address_space]
}

resource "azurerm_subnet" "app" {
  name                 = "App"
  resource_group_name  = var.spoke_resource_group
  virtual_network_name = azurerm_virtual_network.spoke.name

  address_prefixes = [cidrsubnet(local.networks.spoke.address_space, 8, 0)]
}

resource "azurerm_virtual_network_peering" "spoke" {
  name                      = "PeerFromSpokeToHub"
  resource_group_name       = var.spoke_resource_group
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  use_remote_gateways          = false

  timeouts {
    create = "30m"
    delete = "30m"
  }
}
