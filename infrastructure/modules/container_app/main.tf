
resource "azurerm_subnet" "app" {
  name                 = "teqwerk-app-subnet-dev-${var.location}-01"
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
    name                       = var.containerapps_environment
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


# ───────
# Backend Container App (connected to MySQL)
# ───────
resource "azurerm_container_app" "backend" {
  name                         = var.backend_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  secret {
    name                 = var.mysql_admin_password_keyvault_name
    key_vault_secret_id = var.azurerm_key_vault_secret_id
    identity = var.managed_identity_id
  }

  template {

    min_replicas = 1
    max_replicas = 10

    custom_scale_rule {
      name             = "cpu-scaler"
      custom_rule_type = "cpu"
      metadata = {
        type  = "Utilization"
        value = "70"
      }
    }
    
    container {
      name   = "backend"
      image  = "ghcr.io/bpcool/backend:latest"
      cpu    = 1.0
      memory = "2.0Gi"

      ## Terraform added custom default value which slow down container 

      liveness_probe {
        transport                = "HTTPS"
        port                     = 8081
        path                     = "/health"
      }

      readiness_probe {
        transport                 = "HTTPS"
        port                      = 8081
        path                      = "/health"
      }

      startup_probe {
        transport                = "HTTPS"
        port                      = 8081
        path                      = "/health"
      }

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
        secret_name = var.mysql_admin_password_keyvault_name
        # value = "secrets://${var.azurerm_key_vault_id}/${var.mysql_admin_password_keyvault_name}" 
      }
      env {
        name  = "DB_NAME"
        value = var.mysql_database_name
      }
    }
  }

  ingress {
    external_enabled           = true
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
    azurerm_container_app_environment.main
  ]
}


# ───────
# Frontend Container App
# ───────
resource "azurerm_container_app" "frontend" {
  name                         = var.frontend_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  template {
    

    min_replicas = 0
    max_replicas = 5

    container {
      name   = "frontend"

      # App build build pipeline will replace the actual image like below
      # image  = "ghcr.io/bpcool/frontend:latest"
      image  = "nginxdemos/hello:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "BACKEND_URL"
        value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
      }

       liveness_probe {
        transport                = "HTTP"
        port                     = 80
        path                     = "/"
        
        initial_delay            = 2
        interval_seconds         = 10

        timeout                  = 2
        failure_count_threshold = 5
      }

      readiness_probe {
        transport                 = "HTTP"
        port                      = 80
        path                      = "/"
        initial_delay             = 2
        interval_seconds          = 10

        timeout                   = 2
        success_count_threshold   = 1
        failure_count_threshold   = 8
      }
      
    }
    http_scale_rule {
      name                = "http-rule"
      concurrent_requests = 50
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
    azurerm_container_app_environment.main
  ]
}


