# ─────────────────────────────
# log_analytics
# ─────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "logws-teqwerk-dev-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

   tags = {
    environment = "Development"
  }
}