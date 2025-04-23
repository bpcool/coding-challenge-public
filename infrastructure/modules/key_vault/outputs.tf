output "azurerm_key_vault_id" {
  description = "The ID of the Azure azurerm_key_vault"
  value       = azurerm_key_vault.secrets_kv.id
}

output "azurerm_key_vault_name" {
  value       = azurerm_key_vault.secrets_kv.name
}

output "azurerm_key_vault_secret_id" {
  description = "The ID of the Azure azurerm_key_vault_secret"
  value       = azurerm_key_vault_secret.mysql_admin_password_secret.id
}

output "mysql_admin_password_from_keyvault" {
  value       = azurerm_key_vault_secret.mysql_admin_password_secret.value
}

output "mysql_admin_password_keyvault_name" {
  value       = azurerm_key_vault_secret.mysql_admin_password_secret.name
}
