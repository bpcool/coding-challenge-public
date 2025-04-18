output "resource_group_name" {
  value = module.network.resource_group_name
}

output "location" {
  value = module.network.location
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.log_analytics_workspace_id
}

output "mysql_flexible_server_id" {
  value = module.mysql.mysql_flexible_server_id
}

output "mysql_flexible_server_fqdn" {
  value = module.mysql.mysql_flexible_server_fqdn
}
