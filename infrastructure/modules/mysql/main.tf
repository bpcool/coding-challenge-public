# ───────
# MySQL 
# ────────

resource "azurerm_subnet" "mysqlsubnet" {
  name                 = "mysqlsubnet-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

}

resource "azurerm_private_dns_zone" "mysqldns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name =  var.resource_group_name

  tags = {
    environment = "Development"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-vn-link" {
  name                  = "mysql-vn-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysqldns.name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group_name

  tags = {
    environment = "Development"
  }
}

resource "azurerm_mysql_flexible_server" "mysqlserver" {
  name                   = "mysqlfs-teqwerk-dev-westeurope-01"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.mysqlsubnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysqldns.id
  sku_name               = "B_Standard_B1ms"  
  # planned: General purpose GP_Standard_D4ads_v5 (4 vCores, USD 62.42 per vCore) or Business critical Standard_E4ads_v5.  Burstable (1-20 vCores), GP - General purpose (2-96 vCores), Business Critical (2-96 vCores)  
  zone = 2


  tags = {
    environment = "Development"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns-vn-link]
}

resource "azurerm_mysql_flexible_database" "mysqlserverdb" {
  name                = "patientdb-teqwerk-dev-westeurope-01"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysqlserver.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}