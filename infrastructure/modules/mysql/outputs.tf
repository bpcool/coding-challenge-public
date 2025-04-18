output "mysql_flexible_server_id" {
  value = azurerm_mysql_flexible_server.mysqlserver.id
}

output "mysql_flexible_server_fqdn" {
  value = azurerm_mysql_flexible_server.mysqlserver.fqdn
}

output "mysql_database_name" {
  value = azurerm_mysql_flexible_database.mysqlserverdb.name
}