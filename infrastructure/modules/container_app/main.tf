
resource "azurerm_subnet" "app" {
  name                 = "teqwerk-app-subnet-westeurop-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.1.0/24"]   #["10.0.4.0/23"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [address_prefixes]
  }

}

resource "azurerm_container_app_environment" "main" {
    name                       = "appenv-teqwerk-dev-westeurope-01"
    location                   = var.location
    resource_group_name        = var.resource_group_name
    log_analytics_workspace_id = var.log_analytics_workspace_id
    infrastructure_subnet_id   = azurerm_subnet.app.id

    internal_load_balancer_enabled = false
    zone_redundancy_enabled        = false

    workload_profile {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }

    tags = {
    environment = "Development"
  }

  depends_on = [
      azurerm_subnet.app,
      var.log_analytics_workspace_id
  ]

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
      image  = "ghcr.io/bpcool/backend:latest"
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

  ingress {
    external_enabled           = false  # if only internal
    allow_insecure_connections = false
    target_port                = 8081  # <- ✅ backend listens here
    transport                  = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    environment = "Development"
  }

  depends_on = [
    azurerm_container_app_environment.main,
    azurerm_user_assigned_identity.app
  ]
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
      image  = "ghcr.io/bpcool/frontend:latest"
      cpu    = 0.5
      memory = "1Gi"

      # env {
      #   name  = "BACKEND_URL"
      #   value = "https://${azurerm_container_app.backend.name}.${var.location}.azurecontainerapps.io"
      # }

      # with http for testing
      env {
        name  = "BACKEND_URL"
        value = "http://beapp-teqwerk-dev-westeurope-01.internal:8081"    # Prod
        # value = "http://${azurerm_container_app.backend.name}.internal.${var.container_app_env_domain}:8081"
      }

    }

  }

  ingress {
    allow_insecure_connections = false  # should set to false for prod
    external_enabled           = true
    target_port                = 80
    transport                  = "http"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }


  tags = {
    environment = "Development"
  }

  depends_on = [
    azurerm_container_app.backend,
    azurerm_container_app_environment.main,
    azurerm_user_assigned_identity.app
  ]
}
