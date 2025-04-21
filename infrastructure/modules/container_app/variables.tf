
variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "managed_identity_id" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "mysql_database_name" {
  type      = string
}

variable "mysql_flexible_server_fqdn" {
  type      = string
}

variable "containerapps_environment" {
  type = string
}

variable "frontend_app_name" {
  type = string
}

variable "backend_app_name" {
  type = string
}