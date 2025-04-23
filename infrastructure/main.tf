# ──────────────────────────────────────────
# Root Module (infrastructure/main.tf)
# ──────────────────────────────────────────
module "network" {
  source              = "./modules/network"
  location            = var.location
  resource_group_name = var.resource_group_name
}

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_group_name = module.network.resource_group_name
  location            = module.network.location

  depends_on = [module.network]
}


module "key_vault" {
  source                        = "./modules/key_vault"
  resource_group_name           = module.network.resource_group_name
  location                      = var.location
  mysql_admin_password          = var.mysql_admin_password
  log_analytics_workspace_id    = module.log_analytics.log_analytics_workspace_id
  managed_identity_principal_id = module.network.managed_identity_principal_id

  depends_on = [module.log_analytics, module.network]
}

module "mysql" {
  source                             = "./modules/mysql"
  resource_group_name                = module.network.resource_group_name
  virtual_network_name               = module.network.virtual_network_name
  virtual_network_id                 = module.network.virtual_network_id
  location                           = module.network.location
  mysql_admin_username               = var.mysql_admin_username
  log_analytics_workspace_id         = module.log_analytics.log_analytics_workspace_id
  managed_identity_id                = module.network.managed_identity_id
  mysql_admin_password_from_keyvault = module.key_vault.mysql_admin_password_from_keyvault

  depends_on = [module.log_analytics, module.key_vault]
}

# only enable for Data migration CSV to MySQL
module "data_factory" {
  source               = "./modules/data_factory"
  resource_group_name  = module.network.resource_group_name
  location             = var.location
  virtual_network_name = module.network.virtual_network_name

  storage_account_name_for_upload = var.storage_account_name_for_upload

  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id

  azurerm_key_vault_id               = module.key_vault.azurerm_key_vault_id
  mysql_admin_password_keyvault_name = module.key_vault.mysql_admin_password_keyvault_name

  mysql_flexible_server_id = module.mysql.mysql_flexible_server_id
  mysql_admin_username     = var.mysql_admin_username
  mysql_database_name      = module.mysql.mysql_database_name
  mysql_fqdn               = module.mysql.mysql_flexible_server_fqdn

  depends_on = [module.mysql, module.key_vault]
}

module "container_app" {
  source                     = "./modules/container_app"
  resource_group_name        = module.network.resource_group_name
  location                   = module.network.location
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
  virtual_network_name       = module.network.virtual_network_name
  managed_identity_id        = module.network.managed_identity_id

  azurerm_key_vault_id               = module.key_vault.azurerm_key_vault_id
  mysql_admin_password_keyvault_name = module.key_vault.mysql_admin_password_keyvault_name
  mysql_admin_password_from_keyvault = module.key_vault.mysql_admin_password_from_keyvault
  azurerm_key_vault_secret_id        = module.key_vault.azurerm_key_vault_secret_id

  mysql_admin_username       = var.mysql_admin_username
  mysql_database_name        = module.mysql.mysql_database_name
  mysql_flexible_server_fqdn = module.mysql.mysql_flexible_server_fqdn

  containerapps_environment = var.containerapps_environment
  frontend_app_name         = var.frontend_app_name
  backend_app_name          = var.backend_app_name

  depends_on = [module.mysql, module.log_analytics, module.key_vault]
}

