# Network
# ────────

resource "azurerm_resource_group" "main" {
  name     = "rg-teqwerk-dev-westeurope-01"
  location = var.location

   tags = {
    environment = "Development"
  }
}

# resource "azurerm_network_security_group" "example" {
#   name                = "security-group-teqwerk-dev-westeurope-01"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name

#    tags = {
#     environment = "Development"
#   }
# }

resource "azurerm_virtual_network" "main" {
  name                = "vnet-teqwerk-dev-westeurope-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  # dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "Development"
  }
}

