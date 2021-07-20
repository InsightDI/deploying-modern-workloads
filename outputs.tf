output "app_url" {
  value = format("http://%s", azurerm_container_group.app.fqdn)
}
