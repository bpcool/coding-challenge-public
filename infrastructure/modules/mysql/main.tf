# ───────
# MySQL provision
# ────────

resource "azurerm_private_dns_zone" "mysqldns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name =  var.resource_group_name

  tags = {
    environment = "Development"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-vn-link" {
  name                  = "mysql-private_dnszone_vnet-link-teqwerk-dev-${var.location}-01"
  private_dns_zone_name = azurerm_private_dns_zone.mysqldns.name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group_name

  tags = {
    environment = "Development"
  }
}

# # azurerm_mysql_flexible_server -> delegated_subnet_id    = azurerm_subnet.mysqlsubnet.id
# resource "azurerm_subnet" "mysqlsubnet" {
#   name                 = "mysql-subnet-teqwerk-dev-01"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = var.virtual_network_name
#   address_prefixes     = ["10.0.2.0/24"]
#   service_endpoints    = ["Microsoft.Storage"]

#   delegation {
#     name = "fs"
#     service_delegation {
#       name = "Microsoft.DBforMySQL/flexibleServers"
#       actions = [
#         "Microsoft.Network/virtualNetworks/subnets/join/action",
#       ]
#     }
#   }

# }

resource "azurerm_mysql_flexible_server" "mysqlserver" {
  name                   = "mysqlfs-teqwerk-dev-${var.location}-01"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password_from_keyvault
  backup_retention_days  = 7
  
  # Connection via Private endpoint and / or Public access (allowed IP addresses) 
  public_network_access  = "Disabled"

  # # Connection via Private access (VNet Integration)  no ADF or other access
  # # Delete the below "azurerm_private_endpoint" it not required for VNet Integration
  # private_dns_zone_id    = azurerm_private_dns_zone.mysqldns.id
  # delegated_subnet_id    = azurerm_subnet.mysqlsubnet.id
  
  sku_name               = "B_Standard_B1ms"  
  # planned: General purpose GP_Standard_D4ads_v5 (4 vCores, USD 62.42 per vCore) or Business critical Standard_E4ads_v5.  Burstable (1-20 vCores), GP - General purpose (2-96 vCores), Business Critical (2-96 vCores)  
  zone = 2
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  tags = {
    environment = "Development"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns-vn-link]
}

resource "azurerm_mysql_flexible_database" "mysqlserverdb" {
  name                = "patientdb-teqwerk-dev-${var.location}-01"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysqlserver.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"

}

resource "azurerm_mysql_flexible_server_configuration" "setup_ssl" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_mysql_flexible_server.mysqlserver.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysqlserver.name
  value               = "ON"  # ON for production
}



# ───────
# Private Endpoint for MySQL
# ───────
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "privateendpoint-subnet-teqwerk-dev-${var.location}-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.3.0/24"]
}
resource "azurerm_private_endpoint" "mysql_pe" {
  name                = "mysql-private-endpoint-teqwerk-dev-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "mysql-private-service-connection-teqwerk-dev-${var.location}-01"
    private_connection_resource_id = azurerm_mysql_flexible_server.mysqlserver.id
    is_manual_connection           = false
    subresource_names              = ["mysqlServer"]
  }

  private_dns_zone_group {
    name                 = "mysql-dns-zone-group-teqwerk-dev-${var.location}-01"
    private_dns_zone_ids = [azurerm_private_dns_zone.mysqldns.id]
  }

  tags = {
    environment = "Development"
  }
}


resource "azurerm_monitor_diagnostic_setting" "flexi_mysql_logs" {
  name               = "mysqllogsmonitor-teqwerk-dev-${var.location}-01"
  target_resource_id = azurerm_mysql_flexible_server.mysqlserver.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "MySqlAuditLogs"
  }

  enabled_log {
    category = "MySqlSlowLogs"
  }

  metric {
    category = "AllMetrics"
  }
}