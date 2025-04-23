
# ───────
# Azure Key Vault and ADF Integration for MySQL Password
# ────────
data "azurerm_client_config" "current" {}

# Provision the Azure Key Vault
resource "azurerm_key_vault" "secrets_kv" {
  name                        = "kvsecretsteqwerkdev001"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  enabled_for_template_deployment = true

  tags = {
    environment = "Development"
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.managed_identity_principal_id  

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }
}

resource "azurerm_key_vault_secret" "mysql_admin_password_secret" {
  name         = "mysqladminpassword" 
  value        = var.mysql_admin_password 
  key_vault_id = azurerm_key_vault.secrets_kv.id
  content_type = "password"
  
  depends_on = [azurerm_key_vault.secrets_kv]
}


resource "azurerm_monitor_diagnostic_setting" "key_vault_logs" {
  name               = "keyvaultlogsmonitor-teqwerk-dev-${var.location}-01"
  target_resource_id = azurerm_key_vault.secrets_kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

 metric {
    category = "AllMetrics"
   
  }

  depends_on = [azurerm_key_vault.secrets_kv]
}