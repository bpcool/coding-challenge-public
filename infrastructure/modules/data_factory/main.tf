
data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "storageac-for-migration" {
  name                     = var.storage_account_name_for_upload
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.storageac-for-migration.id
  container_access_type = "private"
}


# ────────────────────────────────────────
# Azure Data Factory
# ────────────────────────────────────────

resource "azurerm_data_factory" "this" {
  name                = "adf-teqwerk-dev-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  managed_virtual_network_enabled = true

  public_network_enabled = false

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Development"
  }
}

resource "azurerm_monitor_diagnostic_setting" "adf_logs" {
  name                       = "adflogsmonitor-teqwerk-dev-${var.location}-01"
  target_resource_id         = azurerm_data_factory.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ActivityRuns"
  }

  enabled_log {
    category = "PipelineRuns"
  }

  metric {
    category = "AllMetrics"
  }

  depends_on = [azurerm_data_factory.this]
}

resource "azurerm_role_assignment" "adf_kv_secrets_get" {
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
  role_definition_name = "Key Vault Secrets Officer"
  scope                = var.azurerm_key_vault_id

  depends_on = [
    azurerm_data_factory.this
  ]
}

resource "azurerm_key_vault_access_policy" "adf_secrets_get" {
  key_vault_id  = var.azurerm_key_vault_id
  tenant_id     = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_data_factory.this.identity[0].principal_id

  secret_permissions = [
    "Get"
  ]

  depends_on = [
    azurerm_data_factory.this
  ]
}


resource "azurerm_data_factory_integration_runtime_azure" "managed_vnet_ir" {
  name                          = "integrationruntimedata-teqwerk-dev-${var.location}-01" # Name matches your working manual setup
  data_factory_id               = azurerm_data_factory.this.id
  location                      = azurerm_data_factory.this.location # Should match ADF location

  # This property puts the IR into ADF's Managed VNet
  virtual_network_enabled       = true

  # Optional: Configure compute size if needed for performance
  # compute_type = "General"
  # core_count = 8 # Default
}

# --- Azure Managed Private Endpoint (to MySQL) ---
# This represents the "AzureMySql339" connection you created
resource "azurerm_data_factory_managed_private_endpoint" "mysql_mpe" {
  name                           = "adf-managed-endpoint-teqwerk-dev-${var.location}-01" # Name matches your working manual setup
  data_factory_id                = azurerm_data_factory.this.id

  # Target the Resource ID of your MySQL Flexible Server
  target_resource_id             = var.mysql_flexible_server_id

  # Subresource name for MySQL Flexible Server Private Link
  subresource_name               = "mysqlServer"

  # Ensure the Managed VNet IR is ready before trying to create the MPE
  depends_on = [azurerm_data_factory_integration_runtime_azure.managed_vnet_ir]
}

# ────────────────────────────────────────
# Linked Services
# ────────────────────────────────────────
resource "azurerm_data_factory_linked_service_key_vault" "keyvault_ls" {
  name            = "AzureKeyVaultLinkedService"
  data_factory_id = azurerm_data_factory.this.id
  key_vault_id    = var.azurerm_key_vault_id

  integration_runtime_name = azurerm_data_factory_integration_runtime_azure.managed_vnet_ir.name

  depends_on = [
    azurerm_data_factory.this
  ]
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "blob" {
  name              = "AzureBlobStorageLinkedService"
  data_factory_id   = azurerm_data_factory.this.id
  connection_string = azurerm_storage_account.storageac-for-migration.primary_connection_string
}

resource "azurerm_data_factory_linked_custom_service" "azure_mysql" {
  name            = "AzureMySqlLinkedService_ADF" 
  data_factory_id = azurerm_data_factory.this.id

  type = "AzureMySql" 

  type_properties_json = jsonencode({
    connectionString = "server=${var.mysql_fqdn};port=3306;database=${var.mysql_database_name};uid=${var.mysql_admin_username};sslmode=1;usesystemtruststore=0",
    "password": {
      "type": "AzureKeyVaultSecret",
      "store": {
        "referenceName": azurerm_data_factory_linked_service_key_vault.keyvault_ls.name, 
        "type": "LinkedServiceReference"
      },
      "secretName": var.mysql_admin_password_keyvault_name
    }
  })

  integration_runtime {
    name = azurerm_data_factory_integration_runtime_azure.managed_vnet_ir.name
  }

  depends_on = [
      azurerm_data_factory.this, 
      azurerm_data_factory_integration_runtime_azure.managed_vnet_ir, 
      azurerm_data_factory_linked_service_key_vault.keyvault_ls, 
  ]
}


# ────────────────────────────────────────
# Datasets
# ────────────────────────────────────────
resource "azurerm_data_factory_dataset_delimited_text" "blob_csv" {
  name                = "PatientCSVData"
  data_factory_id     = azurerm_data_factory.this.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.blob.name

  azure_blob_storage_location {
    container = azurerm_storage_container.data.name
    path      = ""
    filename  = "patient_data.csv"
  }

  column_delimiter    = ","
  row_delimiter       = "\n"
  encoding            = "UTF-8"
  first_row_as_header = true

  schema_column {
    name = "id"
    type = "String"
  }
  schema_column {
    name = "full_name"
    type = "String"
  }
   schema_column {
    name = "department"
    type = "String"
  }
  schema_column {
    name = "bed_number"
    type = "String"
  }
}

resource "azurerm_data_factory_dataset_mysql" "patient_table" {
  name            = "AzureMySqlTable1" 
  data_factory_id = azurerm_data_factory.this.id

  linked_service_name = azurerm_data_factory_linked_custom_service.azure_mysql.name

  table_name = "patient" 

  schema_column {
    name = "id"
    type = "Int32"
  }
  schema_column {
    name = "full_name"
    type = "String"
  }
   schema_column {
    name = "department"
    type = "String"
  }
  schema_column {
    name = "bed_number"
    type = "Int32"
  }
}


# ────────────────────────────────────────
# Pipeline
# ────────────────────────────────────────

resource "azurerm_data_factory_pipeline" "copy_csv_to_mysql" {
  name            = "CopyCSVToMySQLPipeline" 
  data_factory_id = azurerm_data_factory.this.id


  activities_json = jsonencode([
    {
      "name": "CopyPatientData", 
      "type": "Copy",
      "dependsOn": [],
      "policy": { 
        "timeout": "7.00:00:00",
        "retry": 0,
        "retryIntervalInSeconds": 30,
        "secureOutput": false,
        "secureInput": false
      },
      "typeProperties": {
        "source": {
          "type": "DelimitedTextSource",
          "storeSettings": {
            "type": "AzureBlobStorageReadSettings",
            "recursive": true
          },
          "formatSettings": {
            "type": "DelimitedTextReadSettings" 
          }
        },
        "sink": {
          "type": "AzureMySqlSink", 
          "writeBatchSize": 1000, 
          "writeBatchTimeout": "00:00:30" 
        },
        "enableStaging": false, 
        "translator": { 
          "type": "TabularTranslator",
          
          "mappings": [
            {
              "source": {
                "name": "id",
                "type": "String",
                "physicalType": "String"
              },
              "sink": {
                "name": "id",
                "type": "Int32",
                "physicalType": "int"
              }
            },
            {
              "source": {
                "name": "full_name",
                "type": "String",
                "physicalType": "String"
              },
              "sink": {
                "name": "full_name",
                "type": "String",
                "physicalType": "text"
              }
            },
            {
              "source": {
                "name": "department",
                "type": "String",
                "physicalType": "String"
              },
              "sink": {
                "name": "department",
                "type": "String",
                "physicalType": "text"
              }
            },
            {
              "source": {
                "name": "bed_number",
                "type": "String",
                "physicalType": "String"
              },
              "sink": {
                "name": "bed_number",
                "type": "Int32",
                "physicalType": "int"
              }
            }
          ],
          "typeConversion": true,
          "typeConversionSettings": {
            "allowDataTruncation": true,
            "treatBooleanAsNumber": false
          }
        }
      },
      "inputs": [
        {
          "referenceName": azurerm_data_factory_dataset_delimited_text.blob_csv.name, # Reference the Terraform CSV Dataset name
          "type": "DatasetReference"
        }
      ],
      "outputs": [
        {
          "referenceName": azurerm_data_factory_dataset_mysql.patient_table.name, # Reference the Terraform MySQL Dataset name
          "type": "DatasetReference"
        }
      ]
    }
  ])

  # Add dependencies to ensure datasets are created before the pipeline
  depends_on = [
    azurerm_data_factory_dataset_delimited_text.blob_csv,
    azurerm_data_factory_dataset_mysql.patient_table
  ]
}
