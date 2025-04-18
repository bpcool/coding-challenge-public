# resource "azurerm_data_factory" "main" {
#   name                = "adf-teqwerk"
#   location            = var.location
#   resource_group_name = var.resource_group_name
# }

# resource "azurerm_data_factory" "example" {
#   name                = "example"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
# }

# resource "azurerm_data_factory_linked_service_mysql" "example" {
#   name              = "example"
#   data_factory_id   = azurerm_data_factory.example.id
#   connection_string = "Server=test;Port=3306;Database=test;User=test;SSLMode=1;UseSystemTrustStore=0;Password=test"
# }

# resource "azurerm_data_factory_dataset_mysql" "example" {
#   name                = "example"
#   data_factory_id     = azurerm_data_factory.example.id
#   linked_service_name = azurerm_data_factory_linked_service_mysql.example.name
# }