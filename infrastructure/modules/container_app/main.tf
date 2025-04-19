
resource "azurerm_subnet" "app" {
  name                 = "teqwerk-app-subnet-westeurop-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.0.0/23"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
  
}

resource "azurerm_container_app_environment" "main" {
    name                       = "appenv-teqwerk-dev-westeurope-01"
    location                   = var.location
    resource_group_name        = var.resource_group_name
    log_analytics_workspace_id = var.log_analytics_workspace_id
    infrastructure_subnet_id   = azurerm_subnet.app.id

    tags = {
    environment = "Development"
  }
  }
  
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-teqwerk-app-dev"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = {
    environment = "Development"
  }
}

# ───────
# Frontend Container App
# ───────
resource "azurerm_container_app" "frontend" {
  name                         = "feapp-teqwerk-dev-westeurope-01"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  template {
    container {
      name   = "frontend"
      image  = "ghcr.io/org/frontend:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  tags = {
    environment = "Development"
  }
}


# ───────
# Backend Container App (connected to MySQL)
# ───────
resource "azurerm_container_app" "backend" {
  name                         = "beapp-teqwerk-dev-westeurope-01"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  template {
    container {
      name   = "backend"
      image  = "ghcr.io/org/backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      # Env variables for MySQL connection
      env {
        name  = "DB_HOST"
        value = var.mysql_flexible_server_fqdn
      }
      env {
        name  = "DB_PORT"
        value = "3306"
      }
      env {
        name  = "DB_USER"
        value = var.mysql_admin_username
      }
      env {
        name  = "DB_PASSWORD"
        value = var.mysql_admin_password
      }
      env {
        name  = "DB_NAME"
        value = var.mysql_database_name
      }
    }
  }

  tags = {
    environment = "Development"
  }
}