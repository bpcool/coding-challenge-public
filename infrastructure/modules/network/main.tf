# Network
# ────────

resource "azurerm_resource_group" "main" {
  name     = "rg-teqwerk-dev-westeurope-01"
  location = var.location

   tags = {
    environment = "Development"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "security-group-teqwerk-dev-westeurope-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

   tags = {
    environment = "Development"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-teqwerk-dev-westeurope-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "app"
    address_prefixes = ["10.0.1.0/24"]
  }

  subnet {
    name             = "mysql"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.example.id
  }

  tags = {
    environment = "Development"
  }
}

# resource "azurerm_subnet" "app" {
#   name                 = "snet-teqwerk-dev-westeurope-01"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# resource "azurerm_subnet" "mysql" {
#   name                 = "snet-teqwerk-dev-westeurope-01"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.2.0/24"]
#   # private_endpoint_network_policies_enabled = true
# }

