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

resource "azurerm_route_table" "firewall" {
  name                          = format("%s%s", "firewall", random_integer.spoke.result)
  location                      = var.location
  resource_group_name           = var.spoke_resource_group
  disable_bgp_route_propagation = false
}

resource "azurerm_route" "outbound_through_firewall" {
  name                = "outboundtointernet"
  resource_group_name = var.spoke_resource_group

  route_table_name       = azurerm_route_table.firewall.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}


resource "azurerm_network_profile" "aci" {
  name                = format("%s%s", "aciprofile", random_integer.spoke.result)
  location            = var.location
  resource_group_name = var.spoke_resource_group

  container_network_interface {
    name = "aci"
    ip_configuration {
      name      = "acinic"
      subnet_id = azurerm_subnet.app.id
    }
  }
}

resource "azurerm_container_group" "app" {
  name                = format("%s%s", "demo-app", random_integer.spoke.result)
  location            = var.location
  resource_group_name = var.spoke_resource_group
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.aci.id
  os_type             = "linux"
  restart_policy      = "OnFailure"

  container {
    name   = "hello-world"
    image  = "microsoft/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = local.tags

  depends_on = [
    azurerm_network_profile.aci
  ]
}

resource "azurerm_firewall_policy" "app" {
  name                = "enable-app-connectivity"
  location            = var.location
  resource_group_name = var.hub_resource_group
}

resource "azurerm_firewall_policy_rule_collection_group" "app" {
  name               = "app-fw-policy"
  firewall_policy_id = azurerm_firewall_policy.app.id
  priority           = 301

  nat_rule_collection {
    name     = "allow-http-inbound"
    priority = 300
    action   = "Dnat"

    rule {
      name                = "allow-http-inbound-dnat"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["80"]
      translated_address  = azurerm_container_group.app.ip_address
      translated_port     = "80"
    }
  }
}
