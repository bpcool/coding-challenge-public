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
}