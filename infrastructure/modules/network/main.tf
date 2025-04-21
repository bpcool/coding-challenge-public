# Network
# ────────

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

   tags = {
    environment = "Development"
  }
}

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-teqwerk-app-dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  tags = {
    environment = "Development"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-teqwerk-dev-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Development"
  }
}

