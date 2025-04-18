output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "location" {
  value = azurerm_resource_group.main.location
}

# output "app_subnet_id" {
#   value = azurerm_subnet.app.id
# }

# output "mysql_subnet_id" {
#   value = azurerm_subnet.mysql.id
# }

