output "app_subnet_id" {
  value = azurerm_subnet.app.id
}

output "app_environment_id" {
  value = azurerm_container_app_environment.main.id
}

output "backend_app_id" {
  value = azurerm_container_app.backend.id
}

output "frontend_app_id" {
  value = azurerm_container_app.frontend.id
}