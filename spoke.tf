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

  delegation {
    name = "aci"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
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

resource "azurerm_container_group" "app" {
  name                = format("%s%s", "demo-app", random_integer.spoke.result)
  location            = var.location
  resource_group_name = var.spoke_resource_group
  ip_address_type     = "Public"
  dns_name_label      = format("%s-%s", var.prefix, random_integer.spoke.result)
  os_type             = "linux"
  restart_policy      = "OnFailure"

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = local.tags

}
