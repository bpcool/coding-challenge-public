output "resource_group_name" {
  value = module.network.resource_group_name
}

output "location" {
  value = module.network.location
}

output "virtual_network_name" {
  value = module.network.virtual_network_name
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

output "mysql_database_name" {
  value = module.mysql.mysql_database_name
}


# output "backend_app_id" {
#   value = module.container_app.backend_app_id
# }

# output "frontend_app_id" {
#   value = module.container_app.frontend_app_id
# }