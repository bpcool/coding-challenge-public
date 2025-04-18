# ──────────────────────────────────────────
# Root Module (infrastructure/main.tf)
# ──────────────────────────────────────────
module "network" {
  source   = "./modules/network"
  location = var.location
}

module "mysql" {
  source                    = "./modules/mysql"
  resource_group_name       = module.network.resource_group_name
  virtual_network_name      = module.network.virtual_network_name
  virtual_network_id        = module.network.virtual_network_id
  network_security_group_id = module.network.network_security_group_id
  location                  = module.network.location
}

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_group_name = module.network.resource_group_name
  location            = module.network.location
}