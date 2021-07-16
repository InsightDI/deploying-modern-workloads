output "app_url" {
  value = format("http://%s", try(azurerm_public_ip.firewall.fqdn, random_integer.hub.result))
}

output "app_ip" {
  value = azurerm_public_ip.firewall.ip_address
}

output "aci_ip" {
  value = azurerm_container_group.app.ip_address
}

output "firewall_ip" {
  value = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}
