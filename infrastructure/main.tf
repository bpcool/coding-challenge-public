# ──────────────────────────────────────────
# Root Module (infrastructure/main.tf)
# ──────────────────────────────────────────
module "network" {
  source   = "./modules/network"
  location = var.location
}

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_group_name = module.network.resource_group_name
  location            = module.network.location

  depends_on = [module.network]
}

module "mysql" {
  source               = "./modules/mysql"
  resource_group_name  = module.network.resource_group_name
  virtual_network_name = module.network.virtual_network_name
  virtual_network_id   = module.network.virtual_network_id
  # network_security_group_id = module.network.network_security_group_id
  location             = module.network.location
  mysql_admin_username = var.mysql_admin_username
  mysql_admin_password = var.mysql_admin_password

  depends_on = [module.log_analytics]
}

module "container_app" {
  source                     = "./modules/container_app"
  resource_group_name        = module.network.resource_group_name
  location                   = module.network.location
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
  virtual_network_name       = module.network.virtual_network_name

  mysql_admin_username       = var.mysql_admin_username
  mysql_admin_password       = var.mysql_admin_password
  mysql_database_name        = module.mysql.mysql_database_name
  mysql_flexible_server_fqdn = module.mysql.mysql_flexible_server_fqdn

  depends_on = [module.mysql, module.log_analytics]
}
