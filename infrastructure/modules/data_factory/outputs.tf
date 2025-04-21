output "data_factory_id" {
  description = "The ID of the Azure Data Factory instance."
  value       = azurerm_data_factory.this.id
}

output "data_factory_name" {
  description = "The name of the Azure Data Factory instance."
  value       = azurerm_data_factory.this.name
}

output "mysql_managed_private_endpoint_id" {
  description = "The ID of the Managed Private Endpoint connection to MySQL."
  value       = azurerm_data_factory_managed_private_endpoint.mysql_mpe.id
}